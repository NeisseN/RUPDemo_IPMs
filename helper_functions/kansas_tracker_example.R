# Code adapted from: https://github.com/aestears/plantTracker
library(sf) #ver 1.0-1.2
library(plantTracker) #ver 1.1.0

dir     <- 'adler_2007_ks/data/quadrat_data/'
dat_dir <- dir
shp_dir <- paste0(dir, "arcexport/")

# quote a series of bare names
quote_bare <- function( ... ){
  substitute( alist(...) ) %>% 
    eval( ) %>% 
    sapply( deparse )
}

# Read in species list, species name changes, and subset species list to perennial grasses
# with minimum cover of 100. Also taking out Carex spp.; 8 species total, might exclude some
# species with the lowest cover later.
sp_list         <- read.csv(paste0(dat_dir,"species_list.csv")) 
sp_list %>% dplyr::arrange( desc(count) ) %>% head(20)
grasses         <- sp_list %>% 
                    dplyr::arrange( desc(count) ) %>% 
                    .[c(7),]

# Read in quad inventory to use as 'inv' list in plantTracker
quad_inv        <- read.csv(paste0(dat_dir,"quadrat_inventory.csv"),
                            sep=',') %>% 
                    dplyr::select(-year)
quadInv_list    <- as.list(quad_inv)
quadInv_list    <- lapply(X = quadInv_list, 
                          FUN = function(x) x[is.na(x) == FALSE])
inv_ks          <- quadInv_list 
names(inv_ks)   <- gsub( '\\.','-',names(inv_ks) )

# Read in shapefiles to create sf dataframe to use as 'dat' in plantTracker
# Adapted from plantTracker How to (Stears et al. 2022)
# Create list of quad names
quadNames <- list.files(shp_dir)
# quadNames <- quadNames[2]

# read in the GIS files
for(i in 1:length(quadNames)){ 
  
  quadNow      <- quadNames[i]
  # quad/year name combination
  quadYears    <- paste0(shp_dir,quadNow,"/") %>% 
    list.files( pattern = ".e00$" ) 
  
  # loop over each year  
  for(j in 1:length(quadYears)){
    
    quad_yr_name  <- quadYears[j]
    shapeNow      <- sf::st_read( dsn   = paste0(shp_dir,quadNow,"/",
                                                 quad_yr_name ),
                                  layer = 'PAL' ) %>% 
      dplyr::select( SCI_NAME, geometry)
    shapeNow$Site <- "KS"
    shapeNow$Quad <- quadNow
    shapeNow$Year <- quad_yr_name %>% 
      gsub(quadNow,'',.) %>% 
      gsub('.e00','',.) %>%
      unlist
    
    # start final data frame
    if(i == 1 & j == 1) {
      
      dat <- shapeNow
      
      # "append" data to the initial data frame  
    } else {
      
      dat <- rbind(dat, shapeNow)
      
    }
  }
  
  # convert year data to numeric
  dat$Year <- as.numeric(dat$Year)
  
  # save data from every plot to not waste time in case an error occurs
  saveRDS(datTrackSpp,
          file= paste0('adler_2007_ks/data/quadrat_data/',
                       "KS_grasses_",quadNow,".rds") )
  
  # remove plot-specific data (already stored)
  rm(dat)
  
}

rds_l    <- list.files( 'adler_2007_ks/data/quadrat_data' ) %>% 
              grep('.rds',.,value=T)

rds_full <- lapply( rds_l, function(x) readRDS( 
                            paste0( 'adler_2007_ks/data/quadrat_data',x) ) 
                    ) %>% 
              bind_rows

# Save the output file so that it doesn't need to be recreated ever again
# saveRDS(rds_full,file="KS_polygons_full.rds")
dat <- readRDS(file= paste0(dir, "/KS_polygons_full.rds") )

# Subset to the species of interest
dat_3grasses <- dat[dat$SCI_NAME %in% grasses$species,] %>% 
  setNames( quote_bare(Species, Site, Quad, 
                       Year, geometry) )
# dat_3grasses$Type <- rep('polygon',93640 )


# And save the subsetted file, too
# saveRDS(dat_3grasses,file="KS_polygons_3grasses.rds")
# dat_3grasses <- readRDS( file=paste0(dir,"KS_polygons_3grasses.rds") )

# Check the inv and dat arguments
checkDat(dat_3grasses, 
         inv_ks, 
         species  = "Species", 
         site     = "Site", 
         quad     = "Quad", 
         year     = "Year", 
         geometry = "geometry")


# Now the data are ready for the trackSpp function
datTrackSpp <- trackSpp( dat_3grasses,
                         inv_ks,
                         dorm         = 0,
                         buff         = 5,
                         clonal       = FALSE,
                         # buffGenet    = 0.05,
                         aggByGenet   = FALSE,
                         flagSuspects = TRUE )


datTrackSpp %>% 
  dplyr::select( age, survives_tplus1 ) %>% 
  drop_na %>% 
  group_by( age ) %>% 
  summarise( surv = sum(survives_tplus1) / n() ) %>% 
  ungroup

datTrackSpp %>% 
  dplyr::select( age, survives_tplus1 ) %>% 
  drop_na %>% 
  .$survives_tplus1 %>% 
  sum

dat_3grasses %>% 
  subset( Quad == 'e1q1-1' & Year == 40) %>% 
  dplyr::select( Species ) %>% 
  plot

# & Year == 43 ) %>% 
  # dplyr::select(Species) %>% 
  # plot

datTrackSpp %>% 
  as.data.frame %>% 
  dplyr::select( Site, Quad, Species, trackID,
                 Year, basalArea_genet, recruit,
                 survives_tplus1, age, size_tplus1,
                 nearEdge, Suspect) %>% 
  write.csv( paste0( 'adler_2007_ks/data/', 
                     'pste/ks_pste.csv'), row.names = F )
