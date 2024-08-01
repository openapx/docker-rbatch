# docker-rbatch
A container extending [openapx/rbin](https://github.com/openapx/docker-rbin) containing a set of core packages for each version of R in `openapx/rbin` for use within the Life Science and other regulated industries.

The container includes 160+ packages, with more added on a continuous basis. 

- Basics (based on tidyverse)
- Survival (survival, flexsurv, survminer, survMisc2, etc.)
- Models (nlme, mmrm, etc.)
- Reporting (rmarkdown, pandoc, officer, r2rtf, etc.)
- Import/Export (xlsx, readxls, xportr, etc.) 


<br>

### Getting Started
The container images are available on Docker Hub (https://hub.docker.com/repository/docker/openapx/rbatch). 

Get the latest release (corresponds to the *main* branch), for Ubuntu in this case, and connect using a standard shell.

```
$ docker pull openapx/rbatch:latest-ubuntu
$ docker run -it openapx/rbatch:latest-ubuntu
```

The latest development release (corresponds to the *development* branch) can be obtained by 
```
docker pull openapx/rbatch:dev-ubuntu
```

<br>

### Basic configuration
All R versions in `openapx/rbatch` is configured using the same principles.

Binary dependencies are listed in the `libs` file at the root of the repository and installed prior to the package installation process. R version specific system and/or binary dependencies are not supported.

The general principle is that all R configurations are *enabled*. If you do not want to use the provided configuration, simply override it.

Each R version is configured using version specific `Renviron.site` and `Rprofile.site` located in the `/opt/R/config/4.x` directory and symbolically linked from each respective R version installation directory. To disable this configuration, simply override the symbolic link. 

The standard R profile sets the default CRAN repository to https://cloud.r-project.org. Currently only CRAN is configured.

The standard R environment sets 

- R version site library to 
  - `/opt/R/libs/4.x/site-library-<R version>`
  - `/opt/R/<R version>/lib/R/site-library`
- {renv} central cache set to `/opt/R/libs/renv-cache` (future support for installing multiple versions of the same R package)

User R libraries remain enabled.

The `openapx/rbatch` container contains a set of administrative R packages that are installed first using the same routine as for any other packages. The list of packages is specified in the `package-adminutils` file in the root of the repository.

The list of R packages to install are listed in the `packages` file in the root of the repository. Any forced R package version installs are specified in `packages-<major.minor.patch>` or `packages-<R major.minor>` files and are processed first and in that order, if they exist. 

Packages listed in the main packages file will use the latest package version available.

Packages listed in the R version specific packages file(s) must specify a package version using the convention `<package>@<version>`.

R package dependencies are not listed in the package specifications and are resolved at time of installation. Packages with forced version will resolve dependencies from the package version `DESCRIPTION` file. The latest version of the dependencies will be used. To force a version of a dependency, include it in the list of forced versions prior to the corresponding reverse dependency.

All packages are installed from source and with tests using the standard environment and profile configuration above and is equivalent to the statement.
```
install.packages( <packages>, 
                  type = "source", 
                  destdir = "/sources/packages", 
                  INSTALL_opts = "--install-tests" )
```

The packages are installed in the R version site library `/opt/R/libs/4.x/site-library-<R version>`.

The `destdir` parameter is used to capture and report the MD-5 and SHA-256 message digest/hash/checksum for the package install sources.

The package install routine will also generate check files for MD-5 (`md5`) and SHA-256 (`sha256`) in each root of the R package installation directory. The check files are compatible with the Linux utilities `md5sum` and `sha256sum`, respectively.

Package install logs are available in the `/logs/R/rbatch/builds` directory in compressed format.


<br>


### Compliance
The `openapx/rbatch` container will be documented and tested to support Life Science GxP-level validation and validation requirements for other regulated industries. 

The formal validation of packages is the responsibility of each individual organization that uses the `openapx/rbatch` container, our aim is to save you a lot of effort.

The compliance documentation planned for `openapx/rbatch` container is the equivalent to Installation Qualification (IQ), Operational Qualification (OQ) and test results and will cover the following steps for each R version.

- Download from source
- Installation logs (IQ)
- Operational checks (OQ)
- Package test archive
- Package test result

<br>

### License
The `openapx/rbatch` container uses the Apache license (see LICENSE file in the root of the repository). 

The `openapx/rbatch` container is based on other software, tools, utilities, etc that in turn has their own individual licenses. As always, it is the responsibility of each individual organization and/or user that uses `openapz/rbatch` to verify that their use is permitted under said licenses.



