# IPM year specific - Anderson 2016 Montana - Bouteloua dactyloides

# Author: Diāna Spurīte
# Co    : Aspen Workman, Aldo Compagnoni, Niklas Neisse
# Email : diana.spurite@posteo.de
# Main  : aldo.compagnoni@idiv.de
# Web   : https://aldocompagnoni.weebly.com/
# Date  : 2025.06.18

# Publication: https://doi.org/10.1890/11-0193.1


# Clean up ---------------------------------------------------------------------
# rm(list = ls())


# Key variables ----------------------------------------------------------------
# Define publication 
v_author_year <- c('anderson_2016')
# Define region abbreviation
v_region_abb  <- c('mt')
# Define species 
v_species     <- c('Bouteloua dactyloides')


# CHECK -- Adaptions -----------------------------------------------------------
# Removal of certain years if unspecified nothing is removed
v_years_re       <- c()
# Define size threshold
v_size_threshold <- c()
# Set a complexity to the growth and survival model 
# (NULL = highest AIC / 0 = intercept / 1 = linear / 2 = quadratic / 3 = cubic)
v_mod_set_gr     <- c()
v_mod_set_su     <- c()


# Main pipeline ----------------------------------------------------------------
# Run the IPM year specific wrapper function
source('pipeline/ipm_year_specific.R')


# Data -------------------------------------------------------------------------

# Dataframe
skim(df)

# Survival
skim(surv_df)

# Grow_df
skim(grow_df)

# Recruitment 
skim(recr_df)

# Population counts
skim(pop_counts)


# Models -----------------------------------------------------------------------
# Survival 
list(su_mod_yr, su_mod_yr_2, su_mod_yr_3)

# Growth
list(gr_mod_yr, gr_mod_yr_2, gr_mod_yr_3)

# Growth variation
gr_var

# Recruitment
rec_mod


# Building the IPM from scratch ------------------------------------------------
# All parameters
skim(all_pars)

# Mean population growth rate
lam_mean_yr

# Observed population growth rate
skim(pop_counts) 

# Geometric mean of yearly population growth rates
lam_mean_count 

# Overall (aggregated) population growth rate
lam_mean_overall

# Mean lambda 
lam_mean_kern


# Building the IPM with ipmr ---------------------------------------------------
ipmr_yr 
