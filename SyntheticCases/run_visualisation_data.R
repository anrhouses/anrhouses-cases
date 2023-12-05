library(ggplot2)
library(viridis)
library(gridExtra)

rm(list=ls())##clear memory

######################################
## LOAD DATA
######################################
rep = "./data/"

case = c("OCSdata_train_clust",
		"OCSdata_train_sparse1","OCSdata_train_sparse2",
		"OCSdata_train_outlier","OCSdata_train_lq","OCSdata_train_imp","OCSdata_full"
	)
nom = c("cluster","sparse1","sparse2","outlier","lq","imp","truth")

## CHOOSE CASE
ic = 1 ## choose case, e.g. ic = 1 = "cluster"
load(paste0(rep,case[ic],".RData"))
dat.tr = OCSdata.train

######################################
## PLOT
######################################
df = data.frame(
	x = dat.tr[,"x"],
	y = dat.tr[,"y"],
	ocs = dat.tr[,"ocs"]
)
p = ggplot(df,aes(x,y,colour = ocs)) + geom_point() + scale_color_viridis(option = "H",limits=c(30,75)) + ggtitle(nom[ic])
