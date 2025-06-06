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
  
  # check whether species have year-specific ipms
  is_yearly_ipm_present <- function(spp_v){
    list.files( paste0(sites[ii],'/R/', spp_v) ) %>% 
      grepl('.ipm_year_specific.R',.) %>% 
      any
  }
    
  # species with yearly IPMs
  spp_yr_i <- sapply( spp_v, is_yearly_ipm_present ) 
  
  # return data frame
  expand.grid( site    = sites[ii],
               species = spp_v[spp_yr_i],
               stringsAsFactors = F ) %>% 
    mutate( site_root  = site_abb[ii] )
  
}

# species by site
spp_by_site <- lapply( 1:5, get_ipm_spp ) %>% bind_rows


# function to run mean models (models with all data comprised)
run_yearly_models <- function( ii ){
  
  # set up the relevant codes
  spp_code_x  <- spp_by_site$species[ii]
  dir         <- paste0( spp_by_site$site[ii],'/R/' )
  root        <- spp_by_site$site_root[ii]
  
  # tell user what species you are working on
  str_c( dir, root, '/', spp_code_x ) %>% print

  # finally run the code  
  source( paste0(dir,  spp_code_x, '/',
                 root, "_", spp_code_x, '_ipm_year_specific.R') )
  
}

# Run plant tracker for all species
lapply( 1:24, run_yearly_models )
