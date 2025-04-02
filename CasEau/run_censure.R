library(ggplot2)
library(intkrige)
library(automap)

rm(list=ls())

################################
### data
load(file="data_Se_xy_f_04-21.RData")
df= data_Se_xy_f
names(df)[3:4] = c("x","y")
ggplot(df,aes(x,y,colour=as.factor(remarque_analyse)))+geom_point()
ggplot(df,aes(x,y,colour=log10(resultat+0.01),size=remarque_analyse))+geom_point()+scale_colour_viridis_b()

df$remarque_analyse[(df$remarque_analyse != 1)] = 2

# New location data preparation
n = 25
xo <- seq(min(df$x), max(df$x), length.out = n)
yo <- seq(min(df$y), max(df$y), length.out = n)
newlocations <- expand.grid(xo, yo)
colnames(newlocations) <- c("x", "y")
sp::coordinates(newlocations) <- c("x", "y")
sp::gridded(newlocations) <- TRUE

################################
### intkrig
df2 =df
n = nrow(df2)
mini = rep(0.0,n)
mini[(df2$remarque_analyse != 2)] = df2$resultat[(df2$remarque_analyse != 2)]
maxi = df2$resultat
df2$maxi = log10(maxi+0.01)
df2$mini = log10(mini+0.01)

sp::coordinates(df2) <- c("x", "y")
plot(newlocations)
points(df2)

interval(df2) <- c("mini", "maxi")
hist(df2$maxi)

### variograms
varios <- intvariogram(df2)
plot(varios)
varioFit <- fit.intvariogram(varios)#, models = gstat::vgm(c( "Sph","Lin", "Sph")))
intvCheck(varios, varioFit)

### pred
preds <- intkrige(df2, newlocations, varioFit,useR=FALSE)
                  
#A = c(1, 1, 0.5), r = 200, eta = 0.9, maxp = 225)

plot(preds, beside = TRUE)

################################
### intkrig
df2 =df
n = nrow(df2)
mini = rep(0.0,n)
mini[(df2$remarque_analyse != 2)] = df2$resultat[(df2$remarque_analyse != 2)]
maxi = df2$resultat
df2$maxi = log10(maxi+0.01)
df2$mini = log10(maxi-0.01)

sp::coordinates(df2) <- c("x", "y")
plot(newlocations)
points(df2)

interval(df2) <- c("mini", "maxi")
hist(df2$maxi)

### variograms
varios <- intvariogram(df2)
plot(varios)
varioFit <- fit.intvariogram(varios)#, models = gstat::vgm(c( "Sph","Lin", "Sph")))
intvCheck(varios, varioFit)

### pred
preds <- intkrige(df2, newlocations, varioFit,useR=FALSE)

#A = c(1, 1, 0.5), r = 200, eta = 0.9, maxp = 225)

plot(preds, beside = TRUE)


################################
### gstat
df3 = df
sp::coordinates(df3) <- c("x", "y")
df3$z = log10(df3$resultat+0.01)
#log10(df3$resultat+0.01)
varios_emp0 = variogram(z~1,df3)
plot(varios_emp0)
vario0 = autofitVariogram(z~1,df3)
plot(vario0)
#v.fit = fit.variogram(varios_emp0, vgm(1, "Sph", 700, 1))
#plot(v.fit)
kriged = krige(z~1, df3, newlocations, model = vario0$var_model)
spplot(kriged["var1.pred"])



