# plantTracker - Anderson 2016 Montana - Artemisia frigida

# Author: Diāna Spurīte
# Co    : Aspen Workman, Aldo Compagnoni, Niklas Neisse
# Email : diana.spurite@posteo.de
# Main  : aldo.compagnoni@idiv.de
# Web   : https://aldocompagnoni.weebly.com/
# Date  : 2025.06.19

# Publication: https://doi.org/10.1890/11-0193.1

# rm(list = ls())

# Specifications ---------------------------------------------------------------
# Define publication
v_author_year      <- c('anderson_2016')
# Define region abbreviation
v_region_abb       <- c('mt')
# Define growth form (grass, forb, shrub, c4)
v_gr_form          <- c('shrub')
# Customized delimiter for `read_delim` function, comma is predefined
v_custom_delimiter <- c(',')
# Model specification (ipm or mpm)
v_model_spec       <- c('ipm')


# Main pipelines ---------------------------------------------------------------
source('pipeline/plant_tracker_01.R')

# Select the x_th species (target species)
head(sp_list, 10)
target_spec <- sp_list %>% .[c(1),]  

source('pipeline/plant_tracker_02.R')


# Exploration ------------------------------------------------------------------
# Quadrat inventory
quad_inv
# Polygon data
dat_target_spec
# Buffer size - regular and genet
st_bbox(dat_target_spec)
v_buff
