

# -- scaffolding
save_sources_to <- "/sources/packages"

if ( ! dir.exists( save_sources_to ) && ! dir.create( save_sources_to, recursive = TRUE ) )
  stop("Could not create ", save_sources_to )


# -- initiate list of packages
pckgs <- list()


# -- derive R version extensions
xrver <- unlist(strsplit( paste( R.Version()[ c( "major", "minor") ], collapse = "." ), ".", fixed = TRUE ))

rvers <- sapply( c(2:length(xrver)), function(i) {
  paste( xrver[1:i], collapse = "." )
} )


# -- identify spec files to process
ftmpl <- file.path( "/opt/openapx/config/rbatch", c( paste( "packages", rev(rvers), sep = "-" ), "packages" ) )

specs <- ftmpl[ file.exists( ftmpl ) ]


# -- deploy each specification

# - get list of available packages
avail <- available.packages()[, "Version"]

for ( xspec in specs ) {

  # - initialize vector of packages
  pckgs <- character(0)

  # - import spec
  lst <- try( base::suppressWarnings( readLines( con = xspec ) ) )

  if ( inherits( lst, "try-error") )
    stop( "Failed to read sepcification ", basename(xspec) )

  pckgs <- lst[ which( trimws(lst) != "" & ! grepl( "^#", trimws(lst), perl = TRUE ) ) ]

  # - install
  #   note: for other than packages ... we install one at a time
  #   note: the spec order is important in packages-<whatever>

  if ( basename(xspec) == "packages" ) {

    # - install
    install.packages( pckgs[ ! pckgs %in% row.names( installed.packages( lib.loc = head(.libPaths(), n = 1) ) ) ], type = "source", destdir = "/sources/packages", INSTALL_opts = "--install-tests" )

  } else {


    for ( xpckg in pckgs ) {

      pckg_name <- gsub( "^(.*)@.*", "\\1", xpckg, perl = TRUE )

      if ( pckg_name  %in% row.names( installed.packages( lib.loc = head(.libPaths(), n = 1) )) )
        next()

      # - install package and dependencies for current version
      if ( pckg_name %in% names(avail) && ( gsub( "^.*@(.*)", "\\1", xpckg, perl = TRUE ) == avail[ pckg_name ] ) ) {
        install.packages( pckg_name, type = "source", destdir = "/sources/packages", INSTALL_opts = "--install-tests" )
        next()
      }


      # - install forced version and dependencies for package

      targz <- gsub( "^(.*)@(.*)", "\\1_\\2.tar.gz", xpckg, perl = TRUE)

      url <- file.path( getOption( "repos")["CRAN"],
                        "src/contrib/Archive/",
                        pckg_name,
                        targz, fsep = "/" )

      dwnld <- try( utils::download.file( url, file.path( save_sources_to, targz ), quiet = TRUE ) )

      if ( inherits( dwnld, "try-error") )
        next()

      # -- determine dependencies

      # working directory to extract info
      extdir <- base::tempfile( pattern = paste0(pckg_name, "-"), tmpdir = base::tempdir(), fileext = "")

      if ( ! dir.create(extdir, recursive = TRUE) )
        stop( "Failed to create extraction area for ", targz )

      # stage file
      file.copy( file.path( save_sources_to, targz ), file.path( extdir, targz) )

      cmd <- paste( "cd", extdir, ";", "tar -xf", file.path( extdir, targz), file.path( pckg_name, "DESCRIPTION", fsep = "/") )

      rc <- system( cmd, intern = TRUE )

      if ( inherits( rc, "try-error") )
        stop( "Command ", cmd, " failed")

      if ( ! file.exists( file.path( extdir, pckg_name, "DESCRIPTION") ) )
        stop( "File DESCRIPTION not extracted to ", file.path( extdir, pckg_name, "DESCRIPTION") )

      # get dependencies for install
      dcf <- desc::desc( file = file.path( extdir, pckg_name, "DESCRIPTION") )

      dil <- paste( unlist( sapply( c( "Depends", "Imports", "LinkingTo"), function(x) {
        if ( is.na(dcf$get(x)) )
          return(NULL)
        else
          return(unname(dcf$get(x)))
      }, USE.NAMES = FALSE ) ), collapse = "," )

      # ... clean up extraction area as no longer needed
      unlink( extdir, recursive = TRUE, force = TRUE )


      dep_items <- trimws(unlist( strsplit( gsub( "\\n", "", dil), ",", fixed = TRUE), use.names = FALSE ))

      deps <- trimws( gsub( "(.*)\\(.*", "\\1", dep_items ) )

      dep_install <- deps[ ! deps %in% c( "R", row.names(installed.packages()) ) ]

      # -- install dependencies
      if ( length(dep_install) > 0 )
        install.packages( dep_install, type = "source", destdir = "/sources/packages", INSTALL_opts = "--install-tests" )

      # -- install source file downloaded above
      install.packages( file.path( save_sources_to, targz ), type = "source", INSTALL_opts = "--install-tests" )

    }   # -- end of for-loop across packages

  }   # -- end of if-else-statement for when spec is not "packages"


  # - generate checksums
  #   note: use list of sources to identify what packages were installed

  algos <- c( "md5", "sha256" ) # our hash algorithms

  for ( xitem in list.dirs( head(.libPaths(), n = 1), recursive = FALSE, full.names = TRUE ) )
    if ( file.exists( file.path(xitem, "DESCRIPTION") ) &&
         ! all( file.exists( file.path(xitem, algos) ) ) )
      for( y in algos ) {

        flst <- list.files( xitem, recursive = TRUE, full.names = FALSE )

        hashes <- sapply( flst[ ! flst %in% algos ] , function( f, hash = y, root = xitem ) {
          digest::digest( file.path( root, f), algo = hash, file = TRUE )
        }, USE.NAMES = TRUE )

        lst <- sapply( sort(names(hashes)), function( x ) {
          paste( hashes[x], x, sep = "  " )  # note: two spaces is important
        } )

        writeLines( lst, con = file.path( xitem, y ) )  # note: should produce a file <algo> in the root of the package install
      }

}

