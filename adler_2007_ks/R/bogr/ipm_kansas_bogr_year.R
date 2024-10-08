# IPM for kansas bocu year specific

# Niklas Neisse
# 2024.09.23

#


# Setting the stage ------------------------------------------------------------
# Remove all objects in the global environment
rm(list = ls()) 
# Set seed for reproducibility
set.seed(100)
options(stringsAsFactors = F)


# Packages ---------------------------------------------------------------------
# Define CRAN packages
.cran_packages <- c("tidyverse",
                    "patchwork",
                    "skimr",
                    "lme4",
                    "bbmle",
                    "ipmr", 
                    "readxl") 
# Check if CRAN packages are installed
.inst <- .cran_packages %in% installed.packages() 
if(any(!.inst)) {
  # Install missing CRAN packages
  install.packages(.cran_packages[!.inst]) 
}
# Load required packages
sapply(.cran_packages, require, character.only = TRUE) 

rm( list = ls() )
options( stringsAsFactors = F )


# Data -------------------------------------------------------------------------

# Define the species variable
species <- "Bouteloua gracilis"
sp_abb  <- tolower(gsub(" ", "", paste(substr(unlist(strsplit(species, " ")), 1, 2), 
                                      collapse = "")))
grow_df <- read.csv(paste0("adler_2007_ks/data/", sp_abb, "/growth_df.csv"))
surv_df <- read.csv(paste0("adler_2007_ks/data/", sp_abb, "/survival_df.csv"))
recr_df <- read.csv(paste0("adler_2007_ks/data/", sp_abb, "/recruitment_df.csv"))
df      <- read.csv(paste0("adler_2007_ks/data/", sp_abb, "/data_df.csv"))

df_long <- 
  pivot_longer(df, cols = c(logsize_t0, logsize_t1 ), 
               names_to = "size", values_to = "size_value" ) %>% 
  select(c(size_t0, year, size,  size_value)) %>% 
  mutate(size = as.factor(size),
         year_fac = as.factor(year))

size_labs        <- c("at time t0", "at time t1")
names(size_labs) <- c("logsize", "logsize_t1")


hist_logsizes_years <-
  df_long %>% 
  ggplot(aes(x = size_value)) +
  geom_histogram(binwidth = 1) +
  facet_grid(year_fac ~ size, 
             scales = "free_y",
             labeller = labeller(size = size_labs)) +
  labs(x = "log(size)",
       y = "Frequency")

ggsave(paste0("adler_2007_ks/results/", sp_abb, "/years_hist_logsizes_years.png"),  
       plot = hist_logsizes_years,
       width = 6, height = 4, dpi = 150)


## Survival 
# function to plot your survival data "binned" per year (instead of "jittered")

# Arguments: data frame, number of bins, 
# UNQUOTED name of size variable, 
# UNQUOTED name of response variable

df_binned_prop_year <- function(ii, df_in, n_bins, siz_var, rsp_var, years){
  
  # make sub-selection of data
  df   <- subset(df_in, year == years$year[ii])
  
  if(nrow(df) == 0) return(NULL)
  
  size_var <- deparse(substitute(siz_var))
  resp_var <- deparse(substitute(rsp_var))
  
  # binned survival probabilities
  h    <- (max(df[,size_var], na.rm = T) - min(df[,size_var], na.rm = T)) / n_bins
  lwr  <-  min(df[,size_var], na.rm = T) + (h * c(0:(n_bins - 1)))
  upr  <- lwr + h
  mid  <- lwr + (1/2 * h)
  
  binned_prop <- function(lwr_x, upr_x, response){
    
    id  <- which(df[,size_var] > lwr_x & df[,size_var] < upr_x) 
    tmp <- df[id,]
    
    if(response == 'prob'){   return(sum (tmp[,resp_var], na.rm = T)/nrow(tmp))}
    if(response == 'n_size'){ return(nrow(tmp))}
    
  }
  
  y_binned <- Map(binned_prop, lwr, upr, 'prob') %>% unlist
  x_binned <- mid
  y_n_size <- Map(binned_prop, lwr, upr, 'n_size') %>% unlist
  
  # output data frame
  data.frame(xx  = x_binned, 
             yy  = y_binned,
             nn  = y_n_size) %>% 
    setNames(c( size_var, resp_var, 'n_size')) %>% 
    mutate(year  = years$year[ii]) %>% 
    drop_na()
  
}

surv_yrs       <- data.frame(year = surv_df$year %>% unique %>% sort)
surv_bin_yrs   <- lapply(1:nrow(surv_yrs), df_binned_prop_year, df, 15, 
                         logsize_t0, survives, surv_yrs)
surv_bin_yrs   <- Filter(function(df) nrow(df) > 0, surv_bin_yrs)

surv_yr_pan_df <- 
  bind_rows(surv_bin_yrs) %>% 
  mutate(transition = paste(paste0(year),
                            substr(paste0(year + 1), 3, 4),
                            sep = '-')) %>% 
  mutate(year = as.integer(year - surv_yrs[1,]))

survival <-
  ggplot(data   = surv_yr_pan_df, aes(x = logsize_t0, y = survives)) +
  geom_point(alpha = 0.5, pch = 16, size = 1, color = 'red') +
  scale_y_continuous(breaks = c(0.1, 0.5, 0.9)) +
  # split in panels
  facet_wrap(.~ transition, ncol = 4) +
  theme_bw() +
  theme(axis.text = element_text(size = 8), title = element_text(size = 10),
        strip.text.y = element_text(size = 5, margin = margin( 0.5, 0.5, 0.5, 0.5, 'mm')),
        strip.text.x = element_text(size = 5, margin = margin( 0.5, 0.5, 0.5, 0.5, 'mm')),
        strip.switch.pad.wrap = unit( '0.5', unit = 'mm' ),
        panel.spacing         = unit( '0.5', unit = 'mm' )) +
  labs(x = expression('log(size)'[t0]),
       y = expression('Survival to time t1'))

ggsave(paste0("adler_2007_ks/results/", sp_abb, "/years_survival.png"), 
       plot = survival,
       width = 4, height = 9, dpi = 150)


## Growth
grow_yr_pan_df <- grow_df %>%
  mutate(transition = paste(paste0(year),
                            substr(paste0(year + 1), 3, 4),
                            sep = '-')) %>% 
  mutate(year       = as.integer(year - 1996))

growth <-
  ggplot(data  = grow_yr_pan_df, aes(x = logsize_t0, y = logsize_t1)) +
  geom_point(alpha = 0.5, pch = 16, size = 0.7, color = 'red') +
  # split in panels
  facet_wrap(.~ transition, ncol = 4) +
  theme_bw() +
  theme(axis.text    = element_text(size = 8),
        title        = element_text(size = 10),
        strip.text.y = element_text(size = 8, margin = margin( 0.5, 0.5, 0.5, 0.5, 'mm')),
        strip.text.x = element_text(size = 8, margin = margin( 0.5, 0.5, 0.5, 0.5, 'mm')),
        strip.switch.pad.wrap = unit('0.5', unit = 'mm'),
        panel.spacing         = unit('0.5', unit = 'mm')) +
  labs(x = expression('log(size)'[t0]),
       y = expression('log(size)'[t1]))

ggsave(paste0("adler_2007_ks/results/", sp_abb, "/years_growth.png"), 
       plot = growth,
       width = 4, height = 9, dpi = 150)


## Recruits
indiv_qd <- surv_df %>%
  group_by(quad) %>%
  count(year) %>% 
  rename(n_adults = n) %>% 
  mutate(year = year + 1)

repr_yr <- indiv_qd %>% 
  left_join(recr_df) %>%
  mutate(repr_pc = nr_quad / n_adults) %>% 
  mutate(year = year - 1) %>% 
  drop_na

recruits <- 
  repr_yr %>% 
  filter(nr_quad  != max(repr_yr$nr_quad)) %>% 
  filter(n_adults != max(repr_yr$n_adults)) %>% 
  ggplot(aes(x = n_adults, y = nr_quad ) ) +
  geom_point(alpha = 1, pch = 16, size = 1, color = 'red') +
  facet_wrap(.~ year, ncol = 4) +
  theme_bw() +
  theme(axis.text    = element_text(size = 8),
        title        = element_text(size = 10),
        strip.text.y = element_text(size = 8, margin = margin(0.5, 0.5, 0.5, 0.5, 'mm')),
        strip.text.x = element_text(size = 8, margin = margin(0.5, 0.5, 0.5, 0.5, 'mm')),
        strip.switch.pad.wrap = unit('0.5', unit = 'mm'),
        panel.spacing         = unit('0.5', unit = 'mm')) +
  labs(x = expression('Number of adults '[ t0]),
       y = expression('Number of recruits '[ t1]))

ggsave(paste0("adler_2007_ks/results/", 
              sp_abb, 
              "/years_recruits.png"), 
       plot = recruits,
       width = 4, height = 9, dpi = 150)

## Recruitment size
rec_size          <- df %>% subset(recruit == 1)
rec_size$year_fac <- as.factor(rec_size$year)

recruitment_size <- 
  rec_size %>% ggplot(aes(x = logsize_t0)) +
  geom_histogram() +
  facet_wrap(year_fac ~ ., scales = "free_y", 
             ncol = 4) +
  labs(x = expression('log(size)'[t0]),
       y = "Frequency")

ggsave(paste0("adler_2007_ks/results/", sp_abb, "/years_recruitment_size.png"), 
       plot = recruitment_size,
       width = 4, height = 9, dpi = 150)


# Fitting vital rate models with the random effect of year ---------------------

# Survival
su_mod_yr   <- glmer(survives ~ logsize_t0 + (logsize_t0 | year), 
                     data = surv_df, family = binomial)
su_mod_yr_2 <- glmer(survives ~ logsize_t0 + logsize_t0_2 + (logsize_t0 | year), 
                     data = surv_df, family = binomial)
su_mod_yr_3 <- glmer(survives ~ logsize_t0 + logsize_t0_2 + 
                       logsize_t0_3 + (logsize_t0 | year), 
                     data = surv_df, family = binomial)
# Model failed to converge with max|grad| = 0.00953909

s_mods <- c(su_mod_yr, su_mod_yr_2, su_mod_yr_3)
AICtab(s_mods, weights = T)
# Assign the best model to the variable
su_mod_yr_bestfit_index <- which.min(AICtab(s_mods, weights = T, sort = F)$dAIC)
su_mod_yr_bestfit <- s_mods[[su_mod_yr_bestfit_index]]
ranef_su <- data.frame(coef(su_mod_yr_bestfit)[1])

years_v  <- c(surv_bin_yrs[[1]][1,'year']:surv_bin_yrs[[length(surv_bin_yrs)]][1,'year'])

v <- rep(NA,length(surv_bin_yrs))
for (ii in 1:length(surv_bin_yrs)) {
  v[ii] <- surv_bin_yrs[[ii]][1,'year']
}

surv_yr_plots <- function(i) {
  surv_temp    <- as.data.frame(surv_bin_yrs[[i]])
  x_temp       <- seq(min(surv_temp$logsize_t0, na.rm = TRUE), 
                      max(surv_temp$logsize_t0, na.rm = TRUE), length.out = 100)
  linear_predictor <- ranef_su[i, 1] 
    if (ncol(ranef_su) >= 2) {
      linear_predictor <- linear_predictor + ranef_su[i, 2] * x_temp}
    if (ncol(ranef_su) >= 3) {
      linear_predictor <- linear_predictor + ranef_su[i, 3] * x_temp^2}
    if (ncol(ranef_su) >= 4) {
      linear_predictor <- linear_predictor + ranef_su[i, 4] * x_temp^3}
  pred_temp <- boot::inv.logit(linear_predictor)
  if (ncol(ranef_su) == 2) {
    line_color <- 'red'
  } else if (ncol(ranef_su) == 3) {
    line_color <- 'green'
  } else if (ncol(ranef_su) == 4) {
    line_color <- 'blue'
  } else {
    line_color <- 'black'  # Default color if there are more than 4 columns
  }  
  pred_temp_df <- data.frame(logsize_t0 = x_temp, survives = pred_temp)
  temp_plot <- surv_temp %>% 
    ggplot() +
    geom_point(aes(x = logsize_t0, y = survives), size = 0.5) +
    geom_line(data = pred_temp_df, aes(x = logsize_t0, y = survives), color = 'green', lwd = 1) +
    labs(title = paste0('19',years_v[i]),
         x = expression('log(size)'[t0]),
         y = expression('Survival probability '[t1])) +
    theme_bw() +
    theme(text         = element_text(size = 5),
          axis.title.y = element_text(  margin = margin(t = 0, 
                                                        r = 0, 
                                                        b = 0, 
                                                        l = 0) ),
          axis.title.x = element_text(  margin = margin(t = 0, 
                                                        r = 0, 
                                                        b = 0, 
                                                        l = 0) ),
          axis.text.x = element_text(  margin  = margin(t = 1, 
                                                        r = 0, 
                                                        b = 0, 
                                                        l = 0) ),
          axis.text.y = element_text(  margin  = margin(t = 0, 
                                                        r = 1, 
                                                        b = 0, 
                                                        l = 0) ),
          plot.title  = element_text( margin = margin(t = 2, 
                                                      r = 0, 
                                                      b = 1, 
                                                      l = 0),
                                      hjust  = 0.5 ),
          plot.margin = margin(t = 0,  
                               r = 0,  
                               b = 0,  
                               l = 5) )  
    
  return(temp_plot)
}

surv_yrs   <- lapply(1:length(surv_bin_yrs), surv_yr_plots)
surv_years <- wrap_plots(surv_yrs) + plot_layout(ncol = 4)

ggsave(paste0("adler_2007_ks/results/", sp_abb, 
              "/years_surv_logsize", su_mod_yr_bestfit_index, ".png"), 
       plot  = surv_years,
       width = 4, height = 9, dpi = 150)


# Growth
gr_mod_yr   <- lmer(logsize_t1 ~ logsize_t0 + (logsize_t0 | year), data = grow_df)
gr_mod_yr_2 <- lmer(logsize_t1 ~ logsize_t0 + logsize_t0_2 + (logsize_t0 | year), data = grow_df)
  # Model failed to converge with max|grad| = 0.0297295
gr_mod_yr_3 <- lmer(logsize_t1 ~ logsize_t0 + logsize_t0_2 + logsize_t0_3 + (logsize_t0 | year), data = grow_df)

g_mods <- c(gr_mod_yr, gr_mod_yr_2, gr_mod_yr_3)
AICtab(g_mods, weights = T)
 # model3 -- incl. quadratic- and cubic terms -- has the lowest AIC, with weight = 0.987 
# Assign the best model
gr_mod_yr_bestfit_index <- which.min(AICtab(g_mods, weights = T, sort = F)$dAIC)
gr_mod_yr_bestfit <- g_mods[[gr_mod_yr_bestfit_index]]
ranef_gr <- data.frame(coef(gr_mod_yr_bestfit)[1])

grow_yr_plots <- function(i){
  
  temp_f <- function(x) {
    linear_predictor <- ranef_gr[which(rownames(ranef_gr) == i), 1]
     if (ncol(ranef_gr) >= 2) {
      linear_predictor <- linear_predictor + 
        ranef_gr[which(rownames(ranef_gr) == i), 2] * x}
    if (ncol(ranef_gr) >= 3) {
     linear_predictor <- linear_predictor + 
       ranef_gr[which(rownames(ranef_gr) == i), 3] * x^2}
    if (ncol(ranef_gr) >= 4) {
     linear_predictor <- linear_predictor + 
       ranef_gr[which(rownames(ranef_gr) == i), 4] * x^3}
  return(linear_predictor)
  }
  if (ncol(ranef_gr) == 2) {line_color <- 'red' } 
  else if (ncol(ranef_gr) == 3) {line_color <- 'green'} 
  else if (ncol(ranef_gr) == 4) {line_color <- 'blue'} 
  else {line_color <- 'black'}
  temp_plot <- grow_df %>% 
    filter(year == i) %>% 
    ggplot() +
    geom_point( aes(x = logsize_t0, y = logsize_t1),
                size = 0.5,
                alpha = 0.5 ) +
    geom_function( fun = temp_f,
                   color = "blue",
                   lwd   = 1 ) +
    geom_abline( intercept = 0,
                 slope     = 1,
                 color     = 'red',
                 lty       = 2 ) +
    # geom_point( aes(x = logsize_t0, y = logsize_t1),
    #             size = 0.5) +
    labs(title = paste0('19',i),
         x = expression('log(size) '[ t0]),
         y = expression('log(size) '[ t1])) +
    theme_bw() +
    theme( text         = element_text( size = 5),
           axis.title.y = element_text(  margin = margin(t = 0, 
                                                         r = 0, 
                                                         b = 0, 
                                                         l = 0) ),
           axis.title.x = element_text(  margin = margin(t = 0, 
                                                         r = 0, 
                                                         b = 0, 
                                                         l = 0) ),
           axis.text.x = element_text(  margin  = margin(t = 1, 
                                                         r = 0, 
                                                         b = 0, 
                                                         l = 0) ),
           axis.text.y = element_text(  margin  = margin(t = 0, 
                                                         r = 1, 
                                                         b = 0, 
                                                         l = 0) ),
           plot.title  = element_text( margin = margin(t = 2, 
                                                       r = 0, 
                                                       b = 1, 
                                                       l = 0),
                                       hjust  = 0.5 ),
           plot.margin = margin(t = 0,  
                                r = 2,  
                                b = 0,  
                                l = 0) )
  
  # if(i %in% c(c(setdiff(1:length(unique(grow_df$year)), 
  #                       seq(1,length(unique(grow_df$year)), 
  #                           by = 4)))) ){
  #   temp_plot <- temp_plot + 
  #     theme(axis.title.y = element_blank(),
  #           axis.title.x = element_text(  margin = margin(t = 0, 
  #                                                         r = 0, 
  #                                                         b = 0, 
  #                                                         l = 0) ),
  #           axis.text.x = element_text(  margin  = margin(t = 1, 
  #                                                         r = 0, 
  #                                                         b = 0, 
  #                                                         l = 0) ),
  #           axis.text.y = element_text(  margin  = margin(t = 0, 
  #                                                         r = 1, 
  #                                                         b = 0, 
  #                                                         l = 0) ),
  #           plot.title  = element_text( margin = margin(t = 2, 
  #                                                       r = 0, 
  #                                                       b = 1, 
  #                                                       l = 0),
  #                                       hjust  = 0.5 ),
  #           plot.margin = margin(t = 0,  
  #                                r = 0,  
  #                                b = 0,  
  #                                l = 0) )
  # }
  return(temp_plot)
}

grow_yrs   <- lapply(sort(unique(grow_df$year)), grow_yr_plots)
grow_years <- wrap_plots(grow_yrs) + plot_layout(ncol = 4)

ggsave(paste0("adler_2007_ks/results/", sp_abb, 
              "/years_growth_logsize", gr_mod_yr_bestfit_index, ".png"), 
       plot = grow_years,
       width = 4, height = 9, dpi = 150)

x      <- fitted(gr_mod_yr_bestfit)
y      <- resid( gr_mod_yr_bestfit)^2
gr_var <- nls(y ~ a * exp(b * x), start = list(a = 1, b = 0))


# Recruitment model
recr_nona_nr_quad <- recr_df %>% filter(!is.na(nr_quad))

rec_mod <- glmer.nb(nr_quad ~ (1 | year), data = recr_nona_nr_quad)

# predict the number of recruits per year per quad
recr_nona_nr_quad <- recr_nona_nr_quad %>% 
  mutate(pred_mod = predict(rec_mod, type = 'response')) 

# sum up the observed and predicted number of recruits per year across all quads
rec_sums_df <- recr_nona_nr_quad %>% 
  group_by(year) %>% 
  summarise(nr_quad  = sum(nr_quad),
            pred_mod = sum(pred_mod)) %>% 
  ungroup

# number of adults present in each year
indiv_yr <- surv_df %>%
  count(year) %>% 
  rename(n_adults = n) %>% 
  mutate(year = year + 1)

# calculate per-capita recruitment rate
repr_pc_yr <- indiv_yr %>% 
  left_join(rec_sums_df ) %>%
  mutate(repr_percapita = pred_mod / n_adults,
         repr_pc_obs    = nr_quad / n_adults,
         year = year - 1 ) %>% 
  drop_na

# recruitment plot
recruitment <-
  repr_pc_yr %>% 
  ggplot() +
  geom_point( aes(x = repr_pc_obs,
                  y = repr_percapita)) +
  geom_abline(aes(intercept = 0, slope = 1),
              color = "red", lwd = 2, alpha = 0.5) +
  labs(x = "Observed per capita recruitment",
       y = "Predicted per capita recruitment") +
  theme_bw()

ggsave(paste0("adler_2007_ks/results/", sp_abb, "/years_recruitment.png"), 
       plot = recruitment,
       width = 6, height = 4, dpi = 150)


# Exporting parameter estimates ------------------------------------------------

# Survival
su_yr_r <-   data.frame(coefficient = paste0("year_", rownames(coef(su_mod_yr_bestfit)$year)), 
                      value       = coef(su_mod_yr_bestfit)$year[,"(Intercept)"])
su_la_r <-   data.frame(coefficient = paste0("logsize_t0", rownames(coef(su_mod_yr_bestfit)$year)), 
                      value       = coef(su_mod_yr_bestfit)$year[,"logsize_t0"])
su_la_r_2 <- data.frame(coefficient = paste0("logsize_t0_2", rownames(coef(su_mod_yr_bestfit)$year)), 
                      value       = coef(su_mod_yr_bestfit)$year[,"logsize_t0_2"])

surv_out_yr <- Reduce(function(...) rbind(...), list(su_la_r, su_yr_r, su_la_r_2)) %>%
  mutate(coefficient = as.character( coefficient ))

write.csv(surv_out_yr, 
          paste0("adler_2007_ks/data/", sp_abb, "/2.surv_pars.csv"), 
          row.names = F)


## Growth
var_fe  <- data.frame(coefficient = names(coef(gr_var)), value = coef(gr_var))
year_re <- data.frame(coefficient = paste0("year_",rownames(coef(gr_mod_yr_bestfit)$year)), 
                      value       = coef(gr_mod_yr_bestfit)$year[,"(Intercept)"])

la_re   <- data.frame(coefficient = paste0("logsize_t0", rownames(coef(gr_mod_yr_bestfit)$year)), 
                      value       = coef(gr_mod_yr_bestfit)$year[,"logsize_t0"])

la_re_2  <- data.frame(coefficient = paste0( "logsize_t0_2", rownames(coef(gr_mod_yr_bestfit)$year)), 
                      value       = coef(gr_mod_yr_bestfit)$year[,"logsize_t0_2"])

grow_out_yr <- Reduce(function(...) rbind(...), list(var_fe, la_re, la_re_2, year_re)) %>%
  mutate(coefficient = as.character(coefficient))

write.csv(grow_out_yr, 
          paste0("adler_2007_ks/data/", sp_abb, "/2.grow_pars.csv"), 
          row.names = F)


## Recruitment
rc_pc <- data.frame(coefficient = paste0("rec_pc_",repr_pc_yr$year),
                    value = repr_pc_yr$repr_percapita)

rc_sz <- data.frame(coefficient = c("rec_siz", "rec_sd"),
                    value = c(mean(rec_size$logsize_t0),
                              sd(rec_size$logsize_t0)))

recr_out_yr <- Reduce(function(...) rbind(...), list(rc_pc, rc_sz)) %>%
  mutate(coefficient = as.character(coefficient))

write.csv(recr_out_yr, 
          paste0("adler_2007_ks/data/",sp_abb,"/2.recr_pars.csv"), 
          row.names = F)


## df constant parameters, fixed effects estimates, and mean parameter estimates
constants <- data.frame(coefficient = c("recr_sz",
                                        "recr_sd",
                                        "a",
                                        "b",
                                        "L",
                                        "U",
                                        "mat_siz"),
                        value = c(mean(rec_size$logsize_t0),
                                  sd(  rec_size$logsize_t0),
                                  as.numeric(coef(gr_var)[1]),
                                  as.numeric(coef(gr_var)[2]),
                                  grow_df$logsize_t0 %>% min,
                                  grow_df$logsize_t0 %>% max,
                                  200))

surv_fe <- data.frame(coefficient = c("surv_b0",
                                      "surv_b1",
                                      "surv_b2"),
                      value       = fixef(su_mod_yr_bestfit))

grow_fe <- data.frame(coefficient = c("grow_b0",
                                      "grow_b1",
                                      "grow_b2"),
                      value       = fixef(gr_mod_yr_bestfit))

rec_fe  <- data.frame(coefficient = "fecu_b0",
                      value       = mean(repr_pc_yr$repr_percapita))

pars_cons <- Reduce(function(...) rbind(...), 
                    list(surv_fe, grow_fe, rec_fe, constants)) %>%
  mutate(coefficient = as.character(coefficient))

rownames(pars_cons) <- 1:nrow(pars_cons)

pars_cons_wide <- as.list(pivot_wider(pars_cons, names_from = "coefficient", 
                                      values_from = "value"))

write.csv(pars_cons_wide, 
          paste0("adler_2007_ks/data/", sp_abb, "/2.pars_cons.csv"), 
          row.names = F)


## df varying parameters
su_b0   <- data.frame(coefficient = paste0("surv_b0_", rownames(coef(su_mod_yr_bestfit)$year)), 
                      value       = coef(su_mod_yr_bestfit)$year[,"(Intercept)"])
su_b1   <- data.frame(coefficient = paste0("surv_b1_", rownames(coef(su_mod_yr_bestfit)$year)), 
                      value       = coef(su_mod_yr_bestfit)$year[,"logsize_t0"])
su_b2   <- data.frame(coefficient = paste0("surv_b2_", rownames(coef(su_mod_yr_bestfit)$year)), 
                      value       = coef(su_mod_yr_bestfit)$year[,"logsize_t0_2"])

grow_b0 <- data.frame(coefficient = paste0("grow_b0_", rownames(coef(gr_mod_yr_bestfit)$year)), 
                      value       = coef(gr_mod_yr_bestfit)$year[,"(Intercept)"])
grow_b1 <- data.frame(coefficient = paste0("grow_b1_", rownames(coef(gr_mod_yr_bestfit)$year)), 
                      value       = coef(gr_mod_yr_bestfit)$year[,"logsize_t0"])
grow_b2 <- data.frame(coefficient = paste0("grow_b2_", rownames(coef(gr_mod_yr_bestfit)$year)), 
                      value       = coef(gr_mod_yr_bestfit)$year[,"logsize_t0_2"])

fecu_b0 <- data.frame(coefficient = paste0("fecu_b0_", repr_pc_yr$year),
                      value       = repr_pc_yr$repr_percapita)

pars_var <- Reduce(function(...) rbind(...), 
                   list(su_b0, su_b1, su_b2, grow_b0, 
                        grow_b1, grow_b2, fecu_b0))

pars_var_wide <- as.list(pivot_wider(pars_var, 
                                     names_from  = "coefficient", 
                                     values_from = "value") )

write.csv(pars_var_wide, 
          paste0("adler_2007_ks/data/", sp_abb, "/2.pars_var.csv"), 
          row.names = F)


# Building the year-specific IPMs from scratch ---------------------------------
## Functions
# Standard deviation of growth model
grow_sd <- function(x, pars) {
  pars$a * (exp(pars$b * x)) %>% sqrt 
}

# Growth from size x to size y
gxy <- function(x, y, pars) {
  return(dnorm(y, mean = pars$grow_b0 + pars$grow_b1*x + pars$grow_b2*x^2,
               sd   = grow_sd(x, pars)))
}

# Inverse logit
inv_logit <- function(x) {exp(x) / (1 + exp(x))}

# Survival of x-sized individual to time t1
sx <- function(x, pars) {
  return(inv_logit(pars$surv_b0 + pars$surv_b1*x + pars$surv_b2*x^2))
}

# Transition of x-sized individual to y-sized individual at time t1
pxy <- function(x, y, pars) {
  return(sx(x, pars) * gxy(x, y, pars))
}

# Per-capita production of y-sized recruits
fy <- function(y, pars, h){
  n_recr  <- pars$fecu_b0
  recr_y  <- dnorm(y, pars$recr_sz, pars$recr_sd) * h
  recr_y  <- recr_y / sum(recr_y)
  f       <- n_recr * recr_y
  return(f)
}

# Kernel
kernel <- function(pars) {
  
  n      <- pars$mat_siz
  L      <- pars$L
  U      <- pars$U
  h      <- (U - L) / n
  b      <- L + c(0:n) * h
  y      <- 0.5 * (b[1:n] + b[2:( n + 1 )])
  
  Fmat   <- matrix(0, n, n)
  Fmat[] <- matrix(fy(y, pars, h), n, n)
  
  Smat   <- c()
  Smat   <- sx(y, pars)
  
  Gmat   <- matrix(0, n, n)
  Gmat[] <- t(outer(y, y, gxy, pars)) * h
  
  Tmat   <- matrix(0, n, n)
  
  for(i in 1:(n / 2)) {
    Gmat[1,i] <- Gmat[1,i] + 1 - sum(Gmat[,i])
    Tmat[,i]  <- Gmat[,i] * Smat[i]
  }
  
  for(i in (n / 2 + 1):n) {
    Gmat[n,i] <- Gmat[n,i] + 1 - sum(Gmat[,i])
    Tmat[,i]  <- Gmat[,i] * Smat[i]
  }
  
  k_yx <- Fmat + Tmat
  
  return(list(k_yx    = k_yx,
              Fmat    = Fmat,
              Tmat    = Tmat,
              Gmat    = Gmat,
              meshpts = y))
  
}


## mean population growth rate
pars_mean <- pars_cons_wide

lambda_ipm <- function(i) {
  return(Re(eigen(kernel(i)$k_yx)$value[1]))
}

lam_mean <- lambda_ipm(pars_mean)
lam_mean


## population growth rates for each year
bogr_yr <- years_v
pars_yr <- vector(mode = "list", length = length(bogr_yr))
extr_value_list <- function(x, field) {
  return(as.numeric(x[paste0(field)] %>% unlist()))
}

prep_pars <- function(i) {
  yr_now    <- bogr_yr[i]
  pars_year <- list(surv_b0 = extr_value_list(pars_var_wide, paste("surv_b0", yr_now, sep = "_" )),
                    surv_b1 = extr_value_list(pars_var_wide, paste("surv_b1", yr_now, sep = "_" )),
                    surv_b2 = extr_value_list(pars_var_wide, paste("surv_b2", yr_now, sep = "_" )),
                    grow_b0 = extr_value_list(pars_var_wide, paste("grow_b0", yr_now, sep = "_" )),
                    grow_b1 = extr_value_list(pars_var_wide, paste("grow_b1", yr_now, sep = "_" )),
                    grow_b2 = extr_value_list(pars_var_wide, paste("grow_b2", yr_now, sep = "_" )),
                    a       = extr_value_list(pars_cons_wide, "a"),
                    b       = extr_value_list(pars_cons_wide, "b"),
                    fecu_b0 = extr_value_list(pars_var_wide, paste("fecu_b0", yr_now, sep = "_" )),
                    recr_sz = extr_value_list(pars_cons_wide, "recr_sz"),
                    recr_sd = extr_value_list(pars_cons_wide, "recr_sd"),
                    L       = extr_value_list(pars_cons_wide, "L"),
                    U       = extr_value_list(pars_cons_wide, "U"),
                    mat_siz = 200)
  return(pars_year)
}

pars_yr <- lapply(1:length(bogr_yr), prep_pars)

# Identify which years contain parameters with numeric(0)
contains_numeric0 <- sapply(pars_yr, function(regular_list) {
  any(sapply(regular_list, function(sublist) {
    identical(sublist, numeric(0))
  }))
})
which_contains_numeric0 <- which(contains_numeric0)
# Exclude these years
# pars_yr <- pars_yr[-which_contains_numeric0]


calc_lambda <- function(i) {
  lam <- Re(eigen(kernel(pars_yr[[i]])$k_yx)$value[1])
  return(lam)
}

lambdas_yr <- lapply(1:(length(bogr_yr)), calc_lambda)
names(lambdas_yr) <- bogr_yr


## Comparing the year-specific lambdas
year_kern <- function(i) {
  return(kernel(pars_yr[[i]])$k_yx)
}

kern_yr <- lapply(1:(length(bogr_yr)), year_kern)

all_mat <- array(dim = c(200, 200, (length(bogr_yr))))

for(i in 1:(length(bogr_yr))) {
  all_mat[,,i] <- as.matrix(kern_yr[[i]])
}

mean_kern <- apply(all_mat, c(1, 2), mean)

lam_mean_kern <- Re(eigen(mean_kern)$value[1])

lam_mean_kern



# Population counts at time t0
pop_counts_t0 <- df %>%
  group_by(year, quad) %>%
  summarize(n_t0 = n()) %>% 
  ungroup %>% 
  mutate(year = year + 1)

# Population counts at time t1
pop_counts_t1 <- df %>%
  group_by(year, quad ) %>%
  summarize(n_t1 = n()) %>% 
  ungroup 

# Calculate observed population growth rates, 
#   accounting for discontinued sampling!
pop_counts <- left_join(pop_counts_t0, 
                        pop_counts_t1) %>% 
  # by dropping NAs, we remove gaps in sampling!
  drop_na %>% 
  group_by(year) %>% 
  summarise(n_t0 = sum(n_t0),
            n_t1 = sum(n_t1)) %>% 
  ungroup %>% 
  mutate(obs_pgr = n_t1 / n_t0) %>% 
  mutate(lambda = lambdas_yr %>% unlist) 
# %>%
#   # removing the first two years
#   filter(year >= min(year)+2)


lam_mean_yr    <- mean(pop_counts$lambda, na.rm = T)
lam_mean_count <- mean(pop_counts$obs_pgr, na.rm = T)

lam_mean_geom <- exp(mean(log(pop_counts$obs_pgr), na.rm = T))
lam_mean_geom

lam_mean_overall <- sum(pop_counts$n_t1) / sum(pop_counts$n_t0)
lam_mean_overall


# projecting a population vector for each year using the year-specific models,
# and compare the projected population to the observed population
count_indivs_by_size <- function(size_vector,
                                 lower_size,
                                 upper_size,
                                 matrix_size){
  
  size_vector %>%
    cut(breaks = seq(lower_size - 0.00001,
                     upper_size + 0.00001,
                     length.out = matrix_size + 1)) %>%
    table %>%
    as.vector
  
}

yr_pop_vec <- function(i) {
  vec_temp <- surv_df %>% filter(year == i) %>% select(logsize_t0) %>% unlist()
  min_sz   <- pars_mean$L
  max_sz   <- pars_mean$U
  pop_vec <- count_indivs_by_size(vec_temp, min_sz, max_sz, 200)
  
  return(pop_vec)
}

year_pop <- lapply(years_v, yr_pop_vec)

proj_pop <- function(i) {
  sum(all_mat[,,i] %*% year_pop[[i]])
}

projected_pop_ns  <- sapply(1:(length(years_v)), proj_pop)

pop_counts_update <- 
  pop_counts %>%
  mutate(proj_n_t1 = projected_pop_ns) %>%
  mutate(proj_pgr  = proj_n_t1/n_t0)

ggplot(pop_counts_update) +
  geom_point( aes(x = lambda,   y = obs_pgr), color = 'brown') +
  geom_point( aes(x = proj_pgr, y = obs_pgr), color = 'red') +
  geom_abline(aes(intercept = 0, slope = 1)) +
  labs(x = "Modeled lambda",
       y = "Observed population growth rate")


# Building the year-specific IPMs with ipmr ------------------------------------
# all of our varying and constant parameters into a single list
all_pars <- c(pars_cons_wide, pars_var_wide)
write.csv(all_pars, 
          paste0("adler_2007_ks/data/", sp_abb, "/all_pars.csv"), 
                 row.names = F)

# proto-IPM with '_yr' suffix
proto_ipm_yr <- init_ipm(sim_gen   = "simple",
                         di_dd     = "di",
                         det_stoch = "det") %>% 
  
  define_kernel(
    name             = "P_yr",
    family           = "CC",
    formula          = s_yr * g_yr,
    s_yr             = plogis(surv_b0_yr + surv_b1_yr * size_1 + 
                               surv_b2_yr * size_1^2), 
    g_yr             = dnorm(size_2, mu_g_yr, grow_sig),
    mu_g_yr          = grow_b0_yr + grow_b1_yr * size_1 + 
      grow_b2_yr * size_1^2 ,
    grow_sig         = sqrt(a * exp(b * size_1)),
    data_list        = all_pars,
    states           = list(c('size')),
    
    # these next two lines are new
    # the first tells ipmr that we are using parameter sets
    uses_par_sets    = TRUE,
    # the second defines the values the yr suffix can assume
    par_set_indices  = list(yr = years_v),
    evict_cor        = TRUE,
    evict_fun        = truncated_distributions(fun    = 'norm',
                                               target = 'g_yr')
  ) %>% 
  
  define_kernel(
    name             = 'F_yr',
    family           = 'CC',
    formula          = fecu_b0_yr * r_d,
    r_d              = dnorm(size_2, recr_sz, recr_sd),
    data_list        = all_pars,
    states           = list(c('size')),
    uses_par_sets    = TRUE,
    par_set_indices  = list(yr = years_v),
    evict_cor        = TRUE,
    evict_fun        = truncated_distributions("norm", "r_d")
  ) %>% 
  
  define_impl(
    make_impl_args_list(
      kernel_names = c(  "P_yr", "F_yr"),
      int_rule     = rep("midpoint", 2),
      state_start  = rep("size", 2),
      state_end    = rep("size", 2)
    )
  ) %>% 
  
  define_domains(
    size = c(all_pars$L,
             all_pars$U,
             all_pars$mat_siz
    )
  ) %>% 
  
  # We also append the suffix in define_pop_state(). This will create a deterministic
  # simulation for every "year"
  define_pop_state(
    n_size_yr = rep(1 / 200, 200)
  )


# Make a dataframe
ipmr_yr       <- make_ipm(proto_ipm  = proto_ipm_yr,
                          iterations = 200)
lam_mean_ipmr <- lambda(ipmr_yr)
lam_out       <- data.frame(coefficient = names(lam_mean_ipmr), 
                            value       = lam_mean_ipmr)
rownames( lam_out) <- 1:(length(years_v))
write.csv(lam_out, 
          paste0("adler_2007_ks/data/", sp_abb, "/lambdas_yr_vec.csv"), 
          row.names = F)

lam_out_wide  <- as.list(pivot_wider(lam_out, names_from = "coefficient", 
                                     values_from         = "value"))
write.csv(lam_out_wide, 
          paste0("adler_2007_ks/data/", sp_abb, "/lambdas_yr.csv"), 
          row.names = F)