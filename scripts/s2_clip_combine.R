##########################################################################################
################## Read, manipulate and write raster data
##########################################################################################

########################################################################################## 
# Contact: remi.dannunzio@fao.org
# Last update: 2018-11-28
##########################################################################################

time_start  <- Sys.time()

aoi <- paste0(eco_dir,"eco93.shp")
aoi_field <- "ECO93_ID"

####################################################################################
####### COMBINE GFC LAYERS
####################################################################################

#################### CREATE GFC TREE COVER MAP IN 2006 AT THRESHOLD
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_treecover2000.tif"),
               paste0(gfc_dir,"gfc_lossyear.tif"),
               paste0(dd_dir,"tmp_gfc_tc_start.tif"),
               paste0("(A>",gfc_threshold,")*((B==0)+(B>5))")
))

#################### SIEVE TO THE MMU
system(sprintf("gdal_sieve.py -st %s %s %s ",
               mmu,
               paste0(dd_dir,"tmp_gfc_tc_start.tif"),
               paste0(dd_dir,"tmp_gfc_tc_start_fsieve.tif")
))

#################### FIX THE HOLES
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_tc_start.tif"),
               paste0(dd_dir,"tmp_gfc_tc_start_fsieve.tif"),
               paste0(dd_dir,"tmp_gfc_tc_start_sieve.tif"),
               paste0("(A>0)*(B>0)*B")
))

#################### DIFFERENCE BETWEEN SIEVED AND ORIGINAL
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_tc_start.tif"),
               paste0(dd_dir,"tmp_gfc_tc_start_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_tc_start_inf.tif"),
               paste0("(A>0)*(A-B)+(A==0)*(B==1)*0")
))


#################### CREATE GFC LOSS MAP AT THRESHOLD between 2006 and 2016
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_treecover2000.tif"),
               paste0(gfc_dir,"gfc_lossyear.tif"),
               paste0(dd_dir,"tmp_gfc_loss.tif"),
               paste0("(A>",gfc_threshold,")*(B>5)*(B<16)")
))

#################### SIEVE TO THE MMU
system(sprintf("gdal_sieve.py -st %s %s %s ",
               mmu,
               paste0(dd_dir,"tmp_gfc_loss.tif"),
               paste0(dd_dir,"tmp_gfc_loss_fsieve.tif")
))

#################### FIX THE HOLES
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_loss.tif"),
               paste0(dd_dir,"tmp_gfc_loss_fsieve.tif"),
               paste0(dd_dir,"tmp_gfc_loss_sieve.tif"),
               paste0("(A>0)*(B>0)*B")
))

#################### DIFFERENCE BETWEEN SIEVED AND ORIGINAL
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_loss.tif"),
               paste0(dd_dir,"tmp_gfc_loss_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_loss_inf.tif"),
               paste0("(A>0)*(A-B)+(A==0)*(B==1)*0")
))


#################### CREATE GFC TREE COVER MASK IN 2016 AT THRESHOLD
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_tc_start.tif"),
               paste0(gfc_dir,"gfc_lossyear.tif"),
               paste0(dd_dir,"tmp_gfc_tc_end.tif"),
               paste0("(A>0)*((B>=16)+(B==0))")
))


#################### SIEVE TO THE MMU
system(sprintf("gdal_sieve.py -st %s %s %s ",
               mmu,
               paste0(dd_dir,"tmp_gfc_tc_end.tif"),
               paste0(dd_dir,"tmp_gfc_tc_end_fsieve.tif")
))

#################### FIX THE HOLES
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_tc_end.tif"),
               paste0(dd_dir,"tmp_gfc_tc_end_fsieve.tif"),
               paste0(dd_dir,"tmp_gfc_tc_end_sieve.tif"),
               paste0("(A>0)*(B>0)*B")
))

#################### DIFFERENCE BETWEEN SIEVED AND ORIGINAL
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_tc_end.tif"),
               paste0(dd_dir,"tmp_gfc_tc_end_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_tc_end_inf.tif"),
               paste0("(A>0)*(A-B)+(A==0)*(B==1)*0")
))

#################### COMBINATION INTO DD MAP (1==Forest, 2==NonForest, 3==gain, 4==deforestation, 5==Degradation 6==ToF, 7==Dg_TOF)
system(sprintf("gdal_calc.py -A %s -B %s -C %s -D %s -E %s -F %s -G %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_tc_start.tif"),
               paste0(dd_dir,"tmp_gfc_loss_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_loss_inf.tif"),
               paste0(dd_dir,"tmp_gfc_tc_end_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_tc_end_inf.tif"),
               paste0(dd_dir,"tmp_gfc_tc_start_fsieve.tif"),
               paste0(dd_dir,"tmp_gfc_tc_start_inf.tif"),
               paste0(dd_dir,"tmp_dd_map.tif"),
               paste0("(A==0)*2+",
                      "(A>0)*((B==0)*(C==0)*((D>0)*1+(E>0)*6)+",
                             "(B>0)*4+",
                             "(C>0)*((F>0)*5+(G>0)*7))")
))

#############################################################
### CROP TO COUNTRY BOUNDARIES
system(sprintf("python %s/oft-cutline_crop.py -v %s -i %s -o %s -a %s",
               scriptdir,
               aoi,
               paste0(dd_dir,"tmp_dd_map.tif"),
               paste0(dd_dir,"tmp_dd_map_aoi.tif"),
               aoi_field
))

#################### CREATE A COLOR TABLE FOR THE OUTPUT MAP
my_classes <- c(0,2,1,4,5,6,7)
my_colors  <- col2rgb(c("black","grey","darkgreen","red","orange","lightgreen","yellow"))

pct <- data.frame(cbind(my_classes,
                        my_colors[1,],
                        my_colors[2,],
                        my_colors[3,]))

write.table(pct,paste0(dd_dir,"color_table.txt"),row.names = F,col.names = F,quote = F)




################################################################################
#################### Add pseudo color table to result
################################################################################
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(dd_dir,"color_table.txt"),
               paste0(dd_dir,"tmp_dd_map_aoi.tif"),
               paste0(dd_dir,"tmp_dd_map_aoi_pct.tif")
))

################################################################################
#################### COMPRESS
################################################################################
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(dd_dir,"tmp_dd_map_aoi_pct.tif"),
               paste0(dd_dir,"tmp_dd_map_aoi_pct_geo.tif")
))

################################################################################
#################### REPROJECT in UTM32N
################################################################################
system(sprintf("gdalwarp -t_srs EPSG:32632 -overwrite -co COMPRESS=LZW %s %s",
               paste0(dd_dir,"tmp_dd_map_aoi_pct_geo.tif"),
               paste0(dd_dir,"dd_map_0616_gt",gfc_threshold,"_20181207.tif")
))

################################################################################
#################### COMPUTE AREAS
################################################################################
system(sprintf("oft-stat %s %s %s",
               paste0(dd_dir,"dd_map_0616_gt",gfc_threshold,"_20181207.tif"),
               paste0(dd_dir,"dd_map_0616_gt",gfc_threshold,"_20181207.tif"),
               paste0(dd_dir,"stats.txt")
))

df <- read.table(paste0(dd_dir,"stats.txt"))[,1:2]
names(df) <- c("class","pixels")
res <- res(raster(paste0(dd_dir,"dd_map_0616_gt",gfc_threshold,"_20181207.tif")))[1]

df$area <- df$pixels * res * res /10000
df
write.csv(df,paste0(dd_dir,"map_areas.csv"),row.names = F)

system(sprintf("rm %s",
               paste0(dd_dir,"tmp*.tif")
))

Sys.time() - time_start
