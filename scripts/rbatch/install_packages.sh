#! /bin/bash

export PCKG_SOURCES=/sources/packages


# -- set up directory structures
echo "-- setting up script scaffolding"
mkdir -p ${PCKG_SOURCES} /logs/R/rbatch


# - install packages for R version

DT_STAMP=$(date +"%Y%m%d-%H%M")

for R_VERSION in $( ls /opt/R | grep "^[0-9].[0-9].[0-9]$" ); do

  if [ -f "$(dirname $0)/R/install_packages.R" ]; then

    RVER_SITE_LIB=/opt/R/libs/4.x/site-library-${R_VERSION} 

    echo "-- installing packages for R ${R_VERSION}"

    echo "   write enable R version site library"
    chmod u+rwx ${RVER_SITE_LIB}    	

    echo "   install packages (this step takes time)"
    /opt/R/${R_VERSION}/bin/R CMD BATCH $(dirname $0)/R/install_packages.R /logs/R/rbatch/${R_VERSION}-install-packages-${DT_STAMP}.log 

    for XSOURCE in $( ls /sources/packages | sort ); do

      _MD5=($(md5sum /sources/packages/${XSOURCE}))
      _SHA256=($(sha256sum /sources/packages/${XSOURCE}))

      echo "   ${XSOURCE} (MD5 ${_MD5} / SHA-256 ${_SHA256})"

      unset _MD5
      unset _SHA256

    done

    echo "   set package installs in R version site library to read-only"
    find ${RVER_SITE_LIB} -type f -exec chmod u+r-wx,g+r-wx,o+r-wx {} \;
    find ${RVER_SITE_LIB} -type d -exec chmod u+rx-w,g+rx-w,o+rx-w {} \;

    echo "   install log assessment"
    grep "^ERROR:" /logs/R/rbatch/${R_VERSION}-install-packages-${DT_STAMP}.log

    gzip -9 /logs/R/rbatch/${R_VERSION}-install-packages-${DT_STAMP}.log

    
    echo "   clean source archive"
    rm -f ${PCKG_SOURCES}/*

  fi

done


