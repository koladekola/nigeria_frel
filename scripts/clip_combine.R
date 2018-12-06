##########################################################################################
################## Read, manipulate and write raster data
##########################################################################################

########################################################################################## 
# Contact: remi.dannunzio@fao.org
# Last update: 2018-11-28
##########################################################################################

time_start  <- Sys.time()

aoi <- paste0(nfi_dir,"eco93.shp")

####################################################################################
####### COMBINE GFC LAYERS
####################################################################################

#################### CREATE GFC TREE COVER MAP IN 2006 AT THRESHOLD
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_treecover2000.tif"),
               paste0(gfc_dir,"gfc_lossyear.tif"),
               paste0(dd_dir,"tmp_gfc_2006_gt",gfc_threshold,".tif"),
               paste0("(A>",gfc_threshold,")*((B==0)+(B>5))*A")
))

#################### CREATE GFC LOSS MAP AT THRESHOLD between 2006 and 2016
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(gfc_dir,"gfc_treecover2000.tif"),
               paste0(gfc_dir,"gfc_lossyear.tif"),
               paste0(dd_dir,"tmp_gfc_loss_0616_gt",gfc_threshold,".tif"),
               paste0("(A>",gfc_threshold,")*(B>5)*(B<16)")
))

#################### SIEVE TO THE MMU
system(sprintf("gdal_sieve.py -st %s %s %s ",
               mmu,
               paste0(dd_dir,"tmp_gfc_loss_0616_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_loss_0616_gt",gfc_threshold,"_fsieve.tif")
))

#################### FIX THE HOLES
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_loss_0616_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_loss_0616_gt",gfc_threshold,"_fsieve.tif"),
               paste0(dd_dir,"tmp_gfc_loss_0616_gt",gfc_threshold,"_sieve.tif"),
               paste0("(A>0)*(B>0)*B")
))

#################### DIFFERENCE BETWEEN SIEVED AND ORIGINAL
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_loss_0616_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_loss_0616_gt",gfc_threshold,"_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_loss_0616_gt",gfc_threshold,"_inf.tif"),
               paste0("(A>0)*(A-B)+(A==0)*(B==1)*0")
))


#################### CREATE GFC TREE COVER MASK IN 2016 AT THRESHOLD
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_2006_gt",gfc_threshold,".tif"),
               paste0(gfc_dir,"gfc_lossyear.tif"),
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,".tif"),
               paste0("(A>0)*((B>=16)+(B==0))")
))


#################### SIEVE TO THE MMU
system(sprintf("gdal_sieve.py -st %s %s %s ",
               mmu,
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,"_fsieve.tif")
))

#################### FIX THE HOLES
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,"_fsieve.tif"),
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,"_sieve.tif"),
               paste0("(A>0)*(B>0)*B")
))

#################### DIFFERENCE BETWEEN SIEVED AND ORIGINAL
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,"_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,"_inf.tif"),
               paste0("(A>0)*(A-B)+(A==0)*(B==1)*0")
))

#################### COMBINATION INTO DD MAP (1==NF, 2==F, 3==Df, 4==Dg, 5==ToF, 6==Dg_TOF)
system(sprintf("gdal_calc.py -A %s -B %s -C %s -D %s -E %s  --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(dd_dir,"tmp_gfc_2006_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_gfc_loss_0616_gt",gfc_threshold,"_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_loss_0616_gt",gfc_threshold,"_inf.tif"),
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,"_sieve.tif"),
               paste0(dd_dir,"tmp_gfc_2016_gt",gfc_threshold,"_inf.tif"),
               paste0(dd_dir,"tmp_dd_map_0616_gt",gfc_threshold,".tif"),
               paste0("(A==0)*1+",
                      "(A>0)*((B==0)*(C==0)*((D>0)*2+(E>0)*5)+",
                             "(B>0)*3+",
                             "(C>0)*((D>0)*4+(E>0)*6))")
))

#############################################################
### CROP TO COUNTRY BOUNDARIES
system(sprintf("python %s/oft-cutline_crop.py -v %s -i %s -o %s -a %s",
               scriptdir,
               aoi,
               #paste0(gadm_dir,"gadm_",the_country,"l1.shp"),
               paste0(dd_dir,"tmp_dd_map_0616_gt",gfc_threshold,".tif"),
               paste0(dd_dir,"tmp_dd_map_0616_gt",gfc_threshold,"aoi_.tif"),
               "ECO93_ID"
))

#################### CREATE A COLOR TABLE FOR THE OUTPUT MAP
my_classes <- c(0,1,2,3,4,5,6)
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
               paste0(dd_dir,"tmp_dd_map_0616_gt",gfc_threshold,"aoi_.tif"),
               paste0(dd_dir,"tmp_dd_map_0616_gt",gfc_threshold,"pct.tif")
))

################################################################################
#################### COMPRESS
################################################################################
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(dd_dir,"tmp_dd_map_0616_gt",gfc_threshold,"pct.tif"),
               paste0(dd_dir,"dd_map_0616_gt",gfc_threshold,"_20181206.tif")
))


system(sprintf("rm %s",
               paste0(dd_dir,"tmp*.tif")
))

Sys.time() - time_start
