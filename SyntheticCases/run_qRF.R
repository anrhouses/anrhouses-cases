library(ranger) ## for qRf
library(scoringRules) ## for CRPS
library(ggplot2) ## for visualisation
library(viridis) ## for colorscale
library(gridExtra) ## for visualisation

rm(list=ls())##clear memory

######################################
## UTILS
######################################
qapprox = function(xout,qy,qq){
	qa = NULL
	for (i in 1:nrow(qy)){
		qa[i] = approx(qq,qy[i,],xout[i])$y
	}
	return(list(qa=qa))
}

Q2 <- function(y,yhat)
  1-mean((y-yhat)^2)/var(y)

MAE <- function(y,yhat)
  mean(abs(y-yhat))

MAXE <- function(y,yhat)
  max(abs(y-yhat))

RMSE <- function(y,yhat)
  sqrt(mean((y-yhat)^2))

CA <- function(y,lo,up){
	id <- NULL
	for (i in 1:length(y)){
		id[i] <- ifelse(y[i] >= lo[i] & y[i] <= up[i], 1, 0)
	}
	sum(id)/length(y)
}

######################################
## LOAD DATA
######################################
rep = "./data/"

## REFERENCE (FULL DATA)
load(paste0(rep,"OCSdata_full.RData"))
dat.te = OCSdata.full

### CASES
case = c("OCSdata_train_clust",
		"OCSdata_train_sparse1","OCSdata_train_sparse2",
		"OCSdata_train_outlier","OCSdata_train_lq","OCSdata_train_imp"
	)
nom = c("cluster","sparse1","sparse2","outlier","lq","imp")

## CHOOSE CASE
ic = 6 ## choose case, e.g. ic = 1 = "cluster"
load(paste0(rep,case[ic],".RData"))
dat.tr = OCSdata.train

######################################
## qRF MODEL
######################################
mod = ranger(ocs~.,data=dat.tr,keep.inbag=TRUE, quantreg = TRUE)

######################################
## PREDICTIONS
######################################
## mean
mpred = predict(mod, dat.te[,-ncol(dat.te)])$predictions

## quantiles
mpred = predict(mod, dat.te[,-ncol(dat.te)])$predictions
qq = seq(0,1,by=0.005)
qpred = unlist(predict(mod, dat.te[,-ncol(dat.te)], type = "quantiles", quantiles = qq)$predictions)

## Samples
Nsim = 100
qsampl = matrix(0,dim(dat.te)[1],Nsim)
qr = matrix(runif(nrow(qpred)*Nsim),ncol=Nsim)
for (i in 1:Nsim){
	print(i)
	qsampl[,i] = unlist(qapprox(xout=qr[,i],qy=qpred,qq=qq))
}

######################################
## PERFORMANCE INDICATORS
######################################

## error
mae = MAE(dat.te[,"ocs"],mpred)
maxe = MAXE(dat.te[,"ocs"],mpred)
rmse = RMSE(dat.te[,"ocs"],mpred)

## prediction interval
qlim = 0.90 ## confidence level
lo = qpred[,which.min(abs(qq-(1-qlim)/2))]
up = qpred[,which.min(abs(qq-(1+qlim)/2))]
w.PI = mean((up-lo)/2)
cov.PI = CA(dat.te[,"ocs"],lo,up)

## Accuracy plot
qqlim = seq(0,1,by=0.05)
cov.pi = NULL
for (i in 1:length(qqlim)){
	lo = qpred[,which.min(abs(qq-(1-qqlim[i])/2))]
	up = qpred[,which.min(abs(qq-(1+qqlim[i])/2))]
	cov.pi[i] = CA(dat.te[,"ocs"],lo,up)
}
Mcov.PI = MAE(qqlim,cov.pi)

## Crps
crps <- NULL
for (k in 1:nrow(dat.te)){
	crps[k] <- crps_sample(dat.te[k,"ocs"],qsampl[k,])
}
Mcrps <- mean(crps)

## example at a given location
loc = 100
plot(ecdf(qsampl[loc,]),main="",xlab= "OCS")
abline(v=dat.te[loc,"ocs"])

######################################
## SAVE
######################################
df0 = data.frame(
	mae,rmse,maxe,
	w.PI, cov.PI, Mcov.PI,
	Mcrps,
	Case = nom[ic]
)

######################################
## PLOT TRUE vs PREDICTION
######################################
df = data.frame(
	x = dat.te[,"x"],
	y = dat.te[,"y"],
	ocs = dat.te[,"ocs"],
	pred = mpred
)
p0 = ggplot(df,aes(x,y,colour = ocs)) + geom_point() + scale_color_viridis(option = "H",limits=c(30,75)) + ggtitle("true")
p1 = ggplot(df,aes(x,y,colour = pred)) + geom_point() + scale_color_viridis(option = "H",limits=c(30,75)) + ggtitle(nom[ic])
grid.arrange(p0,p1,ncol=2)
