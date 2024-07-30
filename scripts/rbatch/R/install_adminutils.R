# R script to install administrative utilities



# -- read list of packages from config

# note: ignores empty lines
# note: use # to comment out a package

pckgs <- character(0)


if ( file.exists( "/opt/openapx/config/rbatch/packages-adminutils") ) {

  utilpckgs <- try( base::suppressWarnings( readLines( con = "/opt/openapx/config/rbatch/packages-adminutils" ) ) )

  if ( ! inherits(utilpckgs, "try-error") )
    pckgs <- utilpckgs[ which( trimws(utilpckgs) != "" & ! grepl( "^#", trimws(utilpckgs), perl = TRUE ) ) ]

}


# -- install
install.packages( pckgs, type = "source", destdir = "/sources/adminutils", INSTALL_opts = "--install-tests" )


# -- generate hashes for each install
for ( x in list.dirs( head(.libPaths(), n = 1), recursive = FALSE, full.names = FALSE ) ) {

  algos <- c( "md5", "sha256" )

  for ( y in algos ) {

    flst <- list.files( file.path( adminlib, x), recursive = TRUE )

    hashes <- sapply( flst[ ! flst %in% algos ] , function( f, hash = y, root = file.path( adminlib, x) ) {
      digest::digest( file.path( root, f), algo = hash, file = TRUE )
    }, USE.NAMES = TRUE )

    lst <- sapply( sort(names(hashes)), function( x ) {
      paste( hashes[x], x, sep = "  " )  # note: two spaces is important
    } )

    writeLines( lst, con = file.path( adminlib, x, y ) )  # note: should produce a file <algo> in the root of the package install
  }

}

