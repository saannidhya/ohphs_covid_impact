# packages
library(haven)
library(tidyverse)
library(Rbearcat)
library(sf)
library(janitor)
library(tmap)
library(zoo)

# location
root <- "C:/Users/rawatsa/OneDrive - University of Cincinnati/SASprojects/ohphs_covid_impact"
data <- paste0(root,"/data")

# importing sas dfs
dfs <- Rbearcat::bcat_import_data(location = data, 
                                  extension = "sas7bdat", 
                                  recursive = TRUE, 
                                  import_function = haven::read_sas)

################################################################
#       conforming SAS dates to R
################################################################
ohphs_empl_by_county <- dfs$ohphs_empl_by_county %>%
    mutate(date = as.Date(date, "1960-01-01"))
ohphs_empl_all <- dfs$ohphs_empl_all %>%
    mutate(date = as.Date(date, "1960-01-01"))
ohphs_empl_by_subcat <- dfs$ohphs_empl_by_subcat %>%
    mutate(date = as.Date(date, "1960-01-01"))
ohphs_job_vars_by_county <- dfs$ohphs_job_vars_by_county %>%
    mutate(date = as.Date(as.yearqtr(date, format = "%YQ%q"), frac = 1 ))
ohps_job_vars_all <- dfs$ohps_job_vars_all %>%
    mutate(date = as.Date(as.yearqtr(date, format = "%YQ%q"), frac = 1 ))


################################################################
#       Calculating job creation and job destruction rate
################################################################

county_df <- inner_join(ohphs_empl_by_county, ohphs_job_vars_by_county, by = c("date"="date","county_name"="county")) %>%
    mutate(job_creation_rate = jobs_created / num_employed,
           job_destruction_rate = jobs_destroyed / num_employed)
all_df <- inner_join(ohphs_empl_all, ohps_job_vars_all, by = c("date"="date")) %>%
    mutate(job_creation_rate = jobs_created / num_employed,
           job_destruction_rate = jobs_destroyed / num_employed)


############################################################################################################
#       Plot Maps: County-level job creation and destruction rate for Ohio (before and after Covid)
############################################################################################################

# importing county sub-division level shape file
oh_shp <- st_read(paste0(data,"/ohio_mapping_files/tl_2016_39_cousub.shp"), stringsAsFactors = FALSE) %>%
                clean_names()
oh_shp$countyfp <- as.numeric(oh_shp$countyfp)

# importing county-mapping table
county_mapping_tbl <- readxl::read_excel(paste0(root,"/docs/county_mapping_tbl.xlsx"), sheet = "mapping")

# aggregating county-subdivision level shape file to county level
oh_shp2 <- inner_join(oh_shp, county_mapping_tbl, by = c("countyfp" = "county_num_df")) %>%
            group_by(county_name) %>%
            summarise() %>%
            ungroup() %>% 
            st_as_sf()

# taking last quarter before Covid hit
plt_df1 <- county_df %>%
                filter(date == "2019-12-31")
# taking first major COVID hit quarter
plt_df2 <- county_df %>%
    filter(date == "2020-06-30")


f1 <- inner_join(plt_df1, oh_shp2) %>% 
    st_as_sf()
f2 <- inner_join(plt_df2, oh_shp2) %>% 
    st_as_sf()

# number employed
ggplot(data = f1) +
    geom_sf(aes(fill = num_employed)) +
    colorspace::scale_fill_continuous_sequential(palette = "Purple-Blue") +
    labs(fill = "healthcare workers") +
    ggthemes::theme_few() + #theme_map() + 
    ggtitle("Total Number of employed workers as of 2019-12-31 ")
ggplot(data = f2) +
    geom_sf(aes(fill = num_employed)) +
    colorspace::scale_fill_continuous_sequential(palette = "Purple-Blue") +
    labs(fill = "healthcare workers") +
    ggthemes::theme_few() +
    ggtitle("Total Number of employed workers as of 2020-06-30")

# job creation rate
par(mfrow =(c(1,2)))
ggplot(data = f1) +
    geom_sf(aes(fill = job_creation_rate)) +
    colorspace::scale_fill_continuous_diverging() +
    labs(fill = "healthcare workers") +
    ggthemes::theme_few() + #theme_map() + 
    ggtitle("Job Creation Rate as of 2019-12-31 ") 

ggplot(data = f2) +
    geom_sf(aes(fill = job_creation_rate)) +
    colorspace::scale_fill_continuous_sequential() +
    labs(fill = "healthcare workers") +
    ggthemes::theme_few() + #theme_map() + 
    ggtitle("Job Creation Rate as of 2020-06-30")

# job destruction rate
ggplot(data = f1) +
    geom_sf(aes(fill = job_destruction_rate)) +
    colorspace::scale_fill_continuous_sequential() +
    labs(fill = "healthcare workers") +
    ggthemes::theme_few() + #theme_map() + 
    ggtitle("Job destruction Rate as of 2019-12-31 ") 

ggplot(data = f2) +
    geom_sf(aes(fill = job_destruction_rate)) +
    colorspace::scale_fill_continuous_sequential() +
    labs(fill = "healthcare workers") +
    ggthemes::theme_few() + #theme_map() + 
    ggtitle("Job destruction Rate as of 2020-06-30")

