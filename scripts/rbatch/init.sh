#! /bin/bash


# -- set up directory structures
echo "-- setting up script scaffolding"
mkdir -p /sources /scripts /logs/R/rbatch


# -- general configuration
CRAN_REPO=https://cloud.r-project.org


# -- common scaffolding for all R versions
RENV_CACHE=/opt/R/libs/renv-cache
mkdir -p ${RENV_CACHE} /opt/R/config/4.x


# -- initiate central configuration for each R version

# note: not writing content to the R version install directory
# note: all configs under /opt/R/config for now

for R_VERSION in $( ls /opt/R | grep "^[0-9].[0-9].[0-9]$" ); do

  # identify lib directory .. sometime it is lib .. on others it is lib64 ... use ../R/library/base/DESCRIPTION (package) as trigger

  echo -n "-- identify lib vs lib64 for R ${R_VERSION}"
  RLIBX=$( find /opt/R/${R_VERSION} -type f -name DESCRIPTION | grep "/R/library/base/DESCRIPTION$" | awk -F/ '{print $5}' )
  echo "  ... found ${RLIBX}"


  echo "-- configuring R ${R_VERSION}"

  # - set up standard R profile
cat<<EOT > /opt/R/config/4.x/${R_VERSION}-Rprofile.site

# -- set CRAN repo mirror
local({
    r <- base::getOption("repos")
    r["CRAN"] <- "${CRAN_REPO}"
    base::options(repos = r)
})


EOT

  ln -s /opt/R/config/4.x/${R_VERSION}-Rprofile.site /opt/R/${R_VERSION}/${RLIBX}/R/etc/Rprofile.site



  # - set up standard R environment
  RVER_SITELIB=/opt/R/libs/4.x/site-library-${R_VERSION}
  mkdir -p ${RVER_SITELIB}


  # use original environ as template
  cp /opt/R/${R_VERSION}/${RLIBX}/R/etc/Renviron /opt/R/config/4.x/${R_VERSION}-Renviron.site

# append rbatch config
cat<<EOT >> /opt/R/config/4.x/${R_VERSION}-Renviron.site

# ---  begin rbatch configuration  ---

# -- site library directories
# note: first level is version specific ... second level is common ... third level is R install
R_LIBS_SITE=${RVER_SITELIB}:/opt/R/${R_VERSION}/lib/R/site-library

# -- renv central cache
RENV_PATHS_CACHE=${RENV_CACHE}

EOT

  ln -s /opt/R/config/4.x/${R_VERSION}-Renviron.site /opt/R/${R_VERSION}/${RLIBX}/R/etc/Renviron.site


  # - install admin packages

  if [ -f "$(dirname $0)/R/install_adminutils.R" ]; then

    echo "-- deploying admin utility packages for R ${R_VERSION}"

    echo "   initiate /sources/adminutils directory"
    mkdir -p /sources/adminutils

    echo "   installing admin utility packages"
    /opt/R/${R_VERSION}/bin/R CMD BATCH --no-restore --no-save $(dirname $0)/R/install_adminutils.R /logs/R/rbatch/${R_VERSION}-install-adminutils.log

    for XSOURCE in $( ls /sources/adminutils | sort ); do

      _MD5=($(md5sum /sources/adminutils/${XSOURCE}))
      _SHA256=($(sha256sum /sources/adminutils/${XSOURCE}))

      echo "   ${XSOURCE} (MD5 ${_MD5} / SHA-256 ${_SHA256})"

      unset _MD5
      unset _SHA256

    done


    echo "   install log assessment"
    grep "^ERROR:" /logs/R/rbatch/${R_VERSION}-install-adminutils.log

    gzip -9 /logs/R/rbatch/${R_VERSION}-install-adminutils.log
    chmod u+r-wx,g+r-wx,o+r-wx /logs/R/rbatch/${R_VERSION}-install-adminutils.log.*

    echo "   clean source archive"
    rm -f /sources/adminutils/*

    echo "   set admin utils install to read-only"
    find ${RVER_SITELIB} -type f -exec chmod u+r-wx,g+r-wx,o+r-wx {} \;
    find ${RVER_SITELIB} -type d -exec chmod u+rx-w,g+rx-w,o+rx-w {} \;

  fi


  # - all done for now
done

# -- end of initiate central configuration for each R version


echo "-- init complete"
