# First part of the plant tracker pipeline

# Author: Niklas Neisse
# Co    : Aspen Workman, Aldo Compagnoni
# Email : neisse.n@protonmail.com
# Main  : aldo.compagnoni@idiv.de
# Web   : https://aldocompagnoni.weebly.com/
# Date  : 2024.10.24

# Code adapted from: https://github.com/aestears/plantTracker
# Adapted from plantTracker How to (Stears et al. 2022)

# Packages ---------------------------------------------------------------------
# Load packages, verify, and download if needed
source('helper_functions/load_packages.R')
load_packages(sf, plantTracker, tidyverse, readr)

# Data -------------------------------------------------------------------------
# Directory 1
pub_dir <- file.path(paste0(author_year, '_', region_abb))
dat_dir <- file.path(pub_dir, 'data', 'quadrat_data')  
# if (!dir.exists(dat_dir)) {
#   dat_dir <- file.path(pub_dir, 'data', 'quad_data')
# }
# Prefix for the script name
script_prefix <- str_c(str_extract(author_year, '^[^_]+'), 
                       str_sub(str_extract(author_year, '_\\d+$'), -2, -1))


# Function to quote bare names for tidy evaluation
quote_bare <- function(...){
  # creates a list of the arguments, but keeps their expressions unevaluated
  # wraps the list, original expressions (the bare names) without evaluation
  substitute(alist(...)) %>% 
    # evaluates the substituted list, which results in a list of the bare name
    eval() %>% 
    # converts the list into their character representations
    # apply to each element, returning a character vector of the names
    sapply(deparse)  
}

# Set the default delimiter (comma)
default_delimiter <- ','

# Check if a custom delimiter is defined (for example, it could be passed as a function argument or set elsewhere)
delimiter <- if (exists('custom_delimiter') && !is.null(custom_delimiter)) {
  custom_delimiter  # Use the custom delimiter if defined
} else {
  default_delimiter # Use the default delimiter (comma) if no custom delimiter is set
}

# Read species list and filter for target species
sp_list <- read_delim(file.path(dat_dir, 
                                paste0(script_prefix, '_species_list.csv')), 
                      delim = delimiter, escape_double = FALSE, 
                      trim_ws = TRUE) %>% 
  as.data.frame() %>% 
  filter(Type == m_type) %>% 
  arrange(desc(counts))


