### test précision balises Ornitella ### 


library(rgdal)
library(geosphere)
library(ggplot2)
library(lubridate)
library(dplyr)
library(tidyverse)
library(stringr)
library(purrr)
library(sp) 

# définir le dossier source
setwd("~/Documents/CERFE/THÈSE_HÉRISSON/Analyses/GPS/Paramètres balises")

# dowload data 
data = read.csv("Fichiers bruts/test_244201_per2.csv")
data$UTC_datetime = as.POSIXct(data$UTC_datetime)
data<-data[,-23] # supprime la colonne X créer sur le fichier source et qui ne sert à rien 

### PRÉPARER LES DONNÉES ###   (à faire tourner plusieurs fois si plusieurs test à différents endroit)

# supprimer les doublons (code Lul)
doublon <-duplicated(data) # permet de voir si des lignes sont dupliquées
length(doublon[doublon == "TRUE"]) # + affiche le nombre de doublons dans la console 
data=distinct(data) # supprime les lignes en double

# supprimer les doublons (mon code)
data$doublon = 0 
for(i in nrow(data)) {
  if(data$UTC_datetime[i]==data$UTC_datetime[i+1]) data$doublon = 1 
}


# créer la colonne RecOrig 
RecOrig<-c(1:nrow(data)) 
data=cbind(RecOrig,data)

# Supprimer les points nuls (pas de loc)
data = subset(data, data$Latitude != 0) # 554
data = subset(data, data$Longitude != 0)

# ajouter colonnes coordonnées en UTM 
xy=data[,c("Latitude","Longitude")]
coordinates(xy) = c("Longitude","Latitude")
proj4string(xy)=CRS("+proj=longlat")
data[,c("X_UTM","Y_UTM")]=as.data.frame(spTransform(xy,CRS("+proj=utm +zone=31")))

# calculer distance au point médian (point réel) = LE 
data$LE = 0
df = data.frame()
for (j in 1:(nrow(data))){  #Va calculer ligne par ligne (nrow) 
  data$LE[j] = sqrt((median(data$X_UTM)- data$X_UTM[j])^2 + (median(data$Y_UTM)- data$Y_UTM[j])^2)    
}
df = rbind(df,data)  

# sortir fichier avec LE 
write.csv(data, "Fichiers bruts LE/test_244201_per2_med.csv")


### ANALYSES DES PARAMÈTRES ### 

# récupérer les 3 fichiers et les fusionner 
cheese =  read.csv("Fichiers bruts LE/test_244201_per1_med.csv")
tomato = read.csv("Fichiers bruts LE/test_244201_per2_med.csv")
ognion = read.csv("Fichiers bruts LE/test_244201_per3_med.csv")
data = rbind(cheese, tomato, ognion)

### 1- exploration LE => LE moyenne / médiane ? 

mean(data$LE) # 6.7 m
median(data$LE) # 4.3 m
min(data$LE) # 0.04 m
max(data$LE) # 252 m 

quantile(data$LE)
quantile(data$LE, probs=seq(0,1,0.05)) #Quantile de 0 à 100%, pas de 5%
quantile(data$LE,probs=seq(0.9,1,0.005)) #Quantile de 90 à 100%, pas de 0,5%

ggplot(data,aes(x=LE))+
  geom_density()+
  scale_x_continuous(name="Erreur de localisation (en mètres)",breaks=seq(0,80,5))+
  scale_y_continuous(name="Densité de points")+
  theme_bw()

### 2- influence de la HDOP

plot(data$hdop)

ggplot(data,aes(x=hdop))+
  geom_density()+
  scale_x_continuous(name="HDOP", breaks=seq(0,15,2))

# LE en fontcion de la HDOP
ggplot(data,aes(x=LE,y=hdop))+
  geom_point() +
  stat_smooth(method="lm") + # Ajoute la droite de régression
  scale_x_continuous(name="Erreur de localisation (en mètres)",breaks=seq(0,80,5)) +
  scale_y_continuous(name="valeur de HDOP",breaks=seq(0,4,0.5))

cor.test(data$LE, data$hdop)  # p-value = 4.792e-16 

length(unique(data$hdop)) # Connaître le nombre de valeur de HDOP pour conna?tre le nombre de ligne de la matrice

# choisir valeur seuil HDOP 
length(unique(data$hdop)) # Connaître le nombre de valeur de HDOP pour conna?tre le nombre de ligne de la matrice
mathdop = matrix(ncol = 4)
for ( i in sort(unique(data$hdop))) { 
  mat <- matrix(c(nrow(subset(data,data$hdop<i)),
                  (nrow(subset(data,data$hdop<i))/nrow(data)*100),
                  print(summary(subset(data,data$hdop<i)$LE)[3]),
                  print(summary(subset(data,data$hdop<i)$LE)[4])),
                ncol=4,byrow=T,nrow=1,dimnames = list(c(i)))
  mathdop = rbind(mathdop,mat)
}

colnames(mathdop)=c("Nb pts restants","% pts restants","Mediane (m)","Moyenne (m)")
mathdop<-data.frame(mathdop)
view(mathdop)


### 3- importance du nombre de satellites 

ggplot(data,aes(x=satcount))+
  geom_density()+
  scale_x_continuous(name="Nombre de satellites",breaks=seq(0,50,2))

#  LE en fonction du nombre de satellites
ggplot(data,aes(x=LE,y=satcount))+
  geom_point() +
  stat_smooth(method="lm") + # Ajoute la droite de r?gression
  scale_x_continuous(name="Erreur de localisation (en m?tres)",breaks=seq(0,60,5)) +
  scale_y_continuous(name="Nombre de satellites",breaks=seq(3,7,1))

cor.test(data$LE,data$satcount,method="kendall") # p-value = 0.9823

# Choisir une valeur seuil de nombre de satellites

length(unique(data$satcount))

matsat=matrix(data=NA,nrow=8,ncol=4)
colnames(matsat)=c("Nb pts restants","% pts restants","M?diane (m)","Moyenne (m)")
rownames(matsat)=1:8

for ( i in 1:8) { 
  
  matsat[i,3:4] = summary(subset(data,data$satcount>=i)$LE)[3:4]
  matsat[i,1]=nrow(subset(data,data$satcount>=i))
  matsat[i,2]=nrow(subset(data,data$satcount>=i))/nrow(data)*100
  
}
matsat<-data.frame(matsat)

## 3- influence de l'altitude 

cor.test(data$LE,data$Altitude_m,method="kendall") # p-value = 2.701e-12

# Exprimer les distances en fonction de l'altitude

ggplot(data,aes(x=LE,y=Altitude_m))+
  geom_point() +
  stat_smooth(method="lm") + # Ajoute la droite de r?gression
  scale_x_continuous(name="Erreur de localisation (en m?tres)",breaks=seq(0,2000,100)) +
  scale_y_continuous(name="Altitude (m)",breaks=seq(0,400,50))

quantile(data$Altitude_m,probs=seq(0,1,0.05))
quantile(data$Altitude_m,probs=seq(0.8,1,0.005))

m100 <- subset(data,data$LE>=20)
quantile(m100$Altitude_m,probs=c(0,0.5,0.9,0.95,0.98,0.99,1))

alt30 <- subset(data,data$Altitude_m<=200)
quantile(alt30$dist.med,probs=seq(0,1,0.05))

## 4- influence de la vitesse 

cor.test(data$LE,data$speed_km_h,method="kendall") # p-value < 2.2e-16

ggplot(data,aes(x=speed_km_h))+
  geom_density()+
  scale_x_continuous(name="Vitesse (km/h)",breaks=seq(0,50,2))

#  LE en fonction de la vitesse 
ggplot(data,aes(x=LE,y=speed_km_h))+
  geom_point() +
  stat_smooth(method="lm") + # Ajoute la droite de r?gression
  scale_x_continuous(name="Erreur de localisation (en m?tres)",breaks=seq(0,60,5)) +
  scale_y_continuous(name="Vitesse",breaks=seq(3,7,1))











