library(tidyverse)
# rm(list=ls())

# Function to quote bare names for tidy evaluation
quote_bare <- function(...){
  substitute(alist(...)) %>% 
    eval() %>% 
    sapply(deparse)  
}

# set up sites -----------------------------------------------------------------

# site directory list
sites     <- quote_bare( adler_2007_ks,
                         anderson_2016_az,
                         # anderson_2016_mt, 
                         christensen_2021_nm,
                         chu_2013_co,
                         zachmann_2016_id )

# site abbreviation (mismatch w/ site unnecessary, however)
site_abb  <- quote_bare( adler07, 
                         anderson16az,
                         # anderson16mt,
                         christensen21,
                         chu13,
                         zachmann16 )

# get IPM species
get_ipm_spp <- function( ii ){
  
  # species list
  spp_v <- list.files( paste0(sites[ii],'/R') ) %>% 
    grep('\\.R', ., invert = TRUE, value = TRUE ) %>%
    grep('_mpm', ., invert = TRUE, value = TRUE ) 
  
  # return data frame
  expand.grid( site    = sites[ii],
               species = spp_v,
               stringsAsFactors = F ) %>% 
    mutate( site_root  = site_abb[ii] )
  
}

# species by site
spp_by_site <- lapply( 1:5, get_ipm_spp ) %>% bind_rows


# function to run mean models (models with all data comprised)
run_mean_models <- function( ii ){
  
  # set up the relevant codes
  spp_code_x  <- spp_by_site$species[ii]
  dir         <- paste0( spp_by_site$site[ii],'/R/' )
  root        <- spp_by_site$site_root[ii]
  
  # tell user what species you are working on
  str_c( dir, root, '/', spp_code_x ) %>% print

  # finally run the code  
  source( paste0(dir,  spp_code_x, '/',
                 root, "_", spp_code_x, '_ipm_mean.R') )
  
}


# TEMPORARY - test Anderson Montana data ---------------------------------------

# species to remove (keep directory to show work that lead to removal)
spp_rm      <- c('spca', 'arca')

# get species codes
only_scrips <- list.files( 'anderson_2016_mt/R/' ) %>% grep('.R',.)
spp_codes   <- list.files( 'anderson_2016_mt/R/' )[-only_scrips]

# tracker scripts 
track_path  <- paste0( 'anderson_2016_mt/R/', spp_codes, 
                       '/anderson16mt_', spp_codes, '_tracker.R' )

lapply( track_path, function(x) source(x) )

# mean IPM  scripts
mean_paths  <- paste0( 'anderson_2016_mt/R/', spp_codes, 
                       '/anderson16mt_', spp_codes, '_ipm_mean.R' )

lapply( mean_paths, function(x){print(paste0(x));source(x)} )



