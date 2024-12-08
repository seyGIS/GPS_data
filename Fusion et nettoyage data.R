### nettoyage et fusion des fichiers pour chaque individu ### 

# ATTENTION : bien modifier le nom du fichier d'entrée et de sorti et la colonne 'Name' 

library(dplyr)
library(lubridate)
library(sp) # coordonnées UTM 
library(ggplot2)

# définir le dossier source
setwd("~/Documents/CERFE/THÈSE_HÉRISSON/Analyses/GPS/Suivis")

# préciser le dossier en fonction de l'individu 
path <-"Hervé/brut total"

# Obtenir la liste des fichiers dans le dossier choisit (ici on suppose qu'ils sont tous au format .csv)
file <- list.files(path = path, pattern = "\\.csv$", full.names = TRUE)

# Créer une liste pour stocker les données de chaque fichier
data_fusion <- lapply(file, function(fichier) {
  
  data <- read.csv(fichier, header = TRUE) # lire les données du fichier
  data$UTC_datetime <- as.POSIXct(data$UTC_datetime)  # format heure 
  data$UTC_datetime <- as.POSIXct(data$UTC_datetime, format = "%Y:%m:%d %H:%M:%S", tz = "UTC")
  
  # supprimer les 12 premières heures après pose balise 
  start <- min(data$UTC_datetime) # calculer heure début 
  start_limit <- start + lubridate::hours(12)  # début + 12h
  data <- data %>% filter(UTC_datetime > start_limit) # filtrer 
  
  # supprimer les dernières heures si besoin 
  #end <- max(data$UTC_datetime) # heure fin
  #end_limit <- end - lubridate::hours(12)
  #data <- data %>% filter(UTC_datetime < end_limit) # filtrer
  
  return(data)
})

# Fusionner tous les fichiers en un seul dataframe
data <- bind_rows(data_fusion)
data = arrange(data,UTC_datetime) # par ordre chronologique

# supprimer les SENSORS
data = subset(data, data$datatype == "GPS")

# supprimer les doublons (code lucille)
doublon <-duplicated(data) # permet de voir si des lignes sont dupliquées
length(doublon[doublon == "TRUE"]) # affiche le nombre de doublons dans la console 
data=distinct(data) # supprime les lignes en double

# ajouter colonne individu et RecOrig en 1ère place
Name = "Hervé"
RecOrig<-c(1:nrow(data))
data = cbind(Name, RecOrig, data)

# subset avec les points nuls pour regarder d'où ils viennent 
nul = subset(data, data$Latitude == 0 | is.na(data$Latitude) == T)
table(nul$device_id) # nombre de point nul par balise 
table(data$device_id) # nombre de point tot par balise (permet de savoir si une balise a eu + de mal)

# conserver un df avec touts les points 
data_tot = data
# Supprimer les points nuls (loc = 0 ou NA)
data = subset(data, data$Latitude != 0) 
data = subset(data, data$Longitude != 0) # en général Latitude suffit 

# ajouter IDtraj : nouveau trajet quand + de 10h entre 2 points (doit donner 1 traj / nuit) 
data$IDtraj = 1
for (i in 2:nrow(data)) {
  time_diff = difftime(data$UTC_datetime[i], data$UTC_datetime[i-1], units = "hours") # diff de temps entre 2 points
  if (time_diff > 10) {
    data$IDtraj[i] = data$IDtraj[i-1] + 1  # Incrémenter l'ID de trajet si diff > 10h
  } else {
    data$IDtraj[i] = data$IDtraj[i-1]  # Maintenir le même ID de trajet
  }
}

# supprimer la colonne X qui sert à rien 
data<-data[,-25]

# ajouter colonnes coordonnées en UTM 
xy=data[,c("Latitude","Longitude")]
coordinates(xy) = c("Longitude","Latitude")
proj4string(xy)=CRS("+proj=longlat")
data[,c("X_UTM","Y_UTM")]=as.data.frame(spTransform(xy,CRS("+proj=utm +zone=31")))

# sortir un nouveau fichier au propre 
write.csv(data, "Hervé/Hervé_tot.csv")




  ### DATA EXPLO ### 

# combien de points nuls par heure ? (est-ce qu'il y a un moment où la balise capte pas ? lien avec activité hérisson ?)
nul$hour = format(nul$UTC_datetime, "%H") # créer une colonne heure

nul_count <- nul %>%  # compter le nombre de point en fonction de la colonne heure
  group_by(hour) %>%
  summarise(nombre_points = n())

ggplot(nul_count, aes(x = hour, y = nombre_points)) +
  geom_col(fill = "skyblue", color = "darkblue") +
  labs(title = "Nombre de points nuls par heure",
       x = "Heure de la journée",
       y = "Nombre de points") +
  theme_minimal()

# combien de points tot / heure 
data_tot$hour = format(data_tot$UTC_datetime, "%H") # créer une colonne heure

tot_count <- data_tot %>%  # compter le nombre de point en fonction de la colonne heure
  group_by(hour) %>%
  summarise(nombre_points = n())

ggplot(tot_count, aes(x = hour, y = nombre_points)) +
  geom_col(fill = "lightgreen", color = "green") +
  labs(title = "Nombre total de points par heure",
       x = "Heure de la journée",
       y = "Nombre de points") +
  theme_minimal()

# % de points nuls par heure 
count = merge(nul_count, tot_count, by="hour", all.x=T,all.y=T) # gérer s'il n'y a pas de nul à certaines heures
for (i in 1:nrow(count)) { # remplacer les NA par des 0 
  if (is.na(count$nombre_points.x[i]) == T) {count$nombre_points.x[i] =0}
}

count$tot = count$nombre_points.x * 100 / count$nombre_points.y
count$percent = 100 - count$tot

ggplot(count, aes(x = hour, y = percent)) +
  geom_col(fill = "gold", color = "goldenrod") +
  labs(title = "Poucentage d'acquisition par heure - HERVÉ balise 30g",
       x = "Heure de la journée",
       y = "taux d'acquistion") +
  theme_minimal()





