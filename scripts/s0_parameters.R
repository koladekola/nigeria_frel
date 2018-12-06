####################################################################################################
####################################################################################################
## Set environment variables
## Contact remi.dannunzio@fao.org 
## 2018/05/04
####################################################################################################
####################################################################################################

####################################################################################################
options(stringsAsFactors = FALSE)

packages <- function(x){
  x <- as.character(match.call()[[2]])
  if (!require(x,character.only=TRUE)){
    install.packages(pkgs=x,repos="http://cran.r-project.org")
    require(x,character.only=TRUE)
  }
}
packages(gfcanalysis)
packages(Hmisc)

### Load necessary packages
library(raster)
library(rgeos)
library(ggplot2)
library(rgdal)
library(stringr)

## Set the working directory
rootdir       <- "~/nigeria_frel/"
gfcstore_dir  <- "~/downloads/gfc_2016/"
the_country   <- "NGA"

setwd(rootdir)
rootdir <- paste0(getwd(),"/")

scriptdir<- paste0(rootdir,"scripts/")
data_dir <- paste0(rootdir,"data/")
gadm_dir <- paste0(rootdir,"data/gadm/")
gfc_dir  <- paste0(rootdir,"data/gfc/")
dd_dir   <- paste0(rootdir,"data/dd_map/")
eco_dir  <- paste0(rootdir,"data/ecozone/")

dir.create(data_dir,showWarnings = F)
dir.create(gadm_dir,showWarnings = F)
dir.create(gfc_dir,showWarnings = F)
dir.create(dd_dir,showWarnings = F)
dir.create(gfcstore_dir,showWarnings = F)

#################### GFC PRODUCTS
gfc_threshold <- 15
beg_year <- 2006
end_year <- 2016
mmu <- 5

#################### PRODUCTS AT THE THRESHOLD
gfc_tc       <- paste0(gfc_dir,"gfc_th",gfc_threshold,"_tc.tif")
gfc_ly       <- paste0(gfc_dir,"gfc_th",gfc_threshold,"_ly.tif")
gfc_gn       <- paste0(gfc_dir,"gfc_gain.tif")
gfc_16       <- paste0(gfc_dir,"gfc_th",gfc_threshold,"_F_",end_year,".tif")
gfc_00       <- paste0(gfc_dir,"gfc_th",gfc_threshold,"_F_",beg_year,".tif")
gfc_mp       <- paste0(gfc_dir,"gfc_map_", beg_year,"_",end_year, "_th",gfc_threshold,".tif")
gfc_mp_crop  <- paste0(gfc_dir,"gfc_map_", beg_year,"_",end_year, "_th",gfc_threshold,"_crop.tif")
gfc_mp_sub   <- paste0(gfc_dir,"gfc_map_", beg_year,"_",end_year, "_th",gfc_threshold,"_sub_crop.tif")
