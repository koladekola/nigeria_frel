####################################################################################################
####################################################################################################
## Get GADM data
## Contact remi.dannunzio@fao.org 
## 2018/05/04
####################################################################################################
####################################################################################################

####################################################################################################
options(stringsAsFactors = FALSE)

### Load necessary packages
library(raster)
library(rgeos)
library(ggplot2)
library(rgdal)

## Set the working directory

## Get List of Countries and select only Cambodia
(gadm_list  <- data.frame(getData('ISO3')))
listcodes   <- "NGA"
countrycode <- listcodes[1]

## Get GADM data and export as shapefile
aoi         <- getData('GADM',path=gadm_dir , country= countrycode, level=1)
writeOGR(aoi,
         paste0(gadm_dir,"gadm_",countrycode,"l1.shp"),
         paste0("gadm_",countrycode,"l1"),
         "ESRI Shapefile",
         overwrite_layer = T)

aoi_kml <- aoi
aoi_kml@data <- aoi_kml@data[,c("OBJECTID","ISO","NAME_1")]

writeOGR(aoi_kml,
         paste0(gadm_dir,"gadm_",countrycode,".kml"),
         paste0("gadm_",countrycode),
         "KML",
         overwrite_layer = T)

levels(as.factor(aoi$NAME_1))
plot(aoi)
## Select one province and export as KML
sub_aoi <- aoi[aoi$NAME_1 == "Cross River",]

plot(sub_aoi,add=T,col="red")

sub_aoi@data <- sub_aoi@data[,c("OBJECTID","ISO")]
writeOGR(sub_aoi,paste0(gadm_dir,"work_aoi_crs.kml"),"work_aoi_crs","KML",overwrite_layer = T)
writeOGR(sub_aoi,paste0(gadm_dir,"work_aoi_sub.shp"),"work_aoi_sub","ESRI Shapefile",overwrite_layer = T)

