# First part of the plant tracker pipeline

# Author: Niklas Neisse
# Co    : Aspen Workman, Diāna Spurīte, Aldo Compagnoni*
# Email : neisse.n@protonmail.com
# Main  : aldo.compagnoni@idiv.de
# Web   : https://aldocompagnoni.weebly.com/
# Date  : 2025.04.29

# Code adapted from: https://github.com/aestears/plantTracker
# Adapted from plantTracker How to (Stears et al. 2022)


# Packages ---------------------------------------------------------------------
# Load packages, verify, and download if needed
source('helper_functions/load_packages.R')
load_packages(sf, plantTracker, tidyverse, readr, janitor)


# Specifications ---------------------------------------------------------------
# Accommodate old variable name set
if (exists('author_year'))      {v_author_year      <- author_year}
if (exists('region_abb'))       {v_region_abb       <- region_abb}
if (exists('gr_form'))          {v_gr_form          <- gr_form}
if (exists('custom_delimiter')) {v_custom_delimiter <- custom_delimiter}


# Directories ------------------------------------------------------------------
dir_pub <- file.path(paste0(v_author_year, '_', v_region_abb))
dir_qud <- file.path(dir_pub, 'data', 'quadrat_data', sep='')  
if (!dir.exists(dir_qud)) {
  dir_qud <- file.path(dir_pub, 'data', 'quad_data')}


# Key variables ----------------------------------------------------------------
# Prefix for the script name
v_script_prefix <- str_c(str_extract(v_author_year, '^[^_]+'), 
                         str_sub(str_extract(v_author_year, '_\\d+$'), -2, -1))

# Define prefix for two of the same author and year
if (
  length(
    list.dirs(
      full.names = TRUE, recursive = FALSE)[grepl(
        paste0('^', v_author_year), basename(
          list.dirs(full.names = TRUE, recursive = FALSE)))]
  ) > 1) {
  v_script_prefix <- paste0(v_script_prefix, v_region_abb)
}

# Set the default delimiter (comma)
v_default_delimiter <- c(',')

# Check if a custom delimiter is defined (for example, it could be passed as a function argument or set elsewhere)
v_delimiter <- if (exists('v_custom_delimiter') && !is.null(v_custom_delimiter)) {
  v_custom_delimiter  # Use the custom delimiter if defined
} else {
  v_default_delimiter # Use the default delimiter (comma) if no custom delimiter is set
}


# Function ---------------------------------------------------------------------
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


# Data -------------------------------------------------------------------------
# Read species list and filter for target species
sp_list <- readr::read_delim(
  {
    f <- list.files(path = dir_qud, pattern = 'species_list.csv', full.names = TRUE)
    match1 <- f[basename(f) == 'species_list.csv']
    match2 <- f[grepl(v_script_prefix, f)]
    if (length(match1) > 0) match1[1] else match2[1]
  },
  delim = v_delimiter,
  col_names = TRUE,
  escape_double = FALSE,
  trim_ws = TRUE,
  show_col_types = FALSE
  ) %>%
  {
    # Capture valid (non-placeholder) column names
    v_spec_col_names <- names(.) %>%
      discard(~ str_detect(.x, '^\\.\\.\\.'))
    
    # If placeholder columns exist, fix by merging
    if (any(str_detect(names(.), '^\\.\\.\\.'))) {
      bind_cols(
        tibble(!!v_spec_col_names[1] := str_c(.[[v_spec_col_merge[1]]], .[[v_spec_col_merge[2]]], sep = ' ')),
        .[, -v_spec_col_merge]
      ) %>%
        set_names(v_spec_col_names)
    } else {
      .
    }
  } %>%
  as.data.frame() %>%
  { 
    # Rename 'type' or 'form' to 'growthForm' if they exist
    if('growthForm' %in% colnames(.)) {
      . <- rename(., growth_form = growthForm)
    }
    if('type' %in% colnames(.)) {
      . <- rename(., growth_form = type)
    }
    if('form' %in% colnames(.)) {
      . <- rename(., growth_form = form)
    }
    .
  } %>% 
  filter(
    if(tolower(v_gr_form) == 'grass') {
      # If 'grass' is specified, include 'grass', 'c3', 'c4'
      tolower(growth_form) %in% c('grass', 'c3', 'c4', 'shortgrass')  
    } else {
      # Otherwise, filter exactly by the specified growth_form
      tolower(growth_form) == tolower(v_gr_form)  
    }
  ) %>% 
  {
    if ('count' %in% colnames(.)) {
      arrange(., desc(count))
    } else if ('counts' %in% colnames(.)) {
      arrange(., desc(counts))
    } else {
      if (v_gr_form == 'forb') {
        arrange(., desc(if ('density' %in% colnames(.)){density} else {pointFeatures}))
      } else {
        arrange(., desc(if ('cover' %in% colnames(.)){cover} else {polygonFeatures}))
      }
    }
  }
