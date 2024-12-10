# GPS_data
cleaning and processing GPS data

# Notice : Traitement des données GPS Hérisson


## I – Choix des paramètres statiques   

_script : Test_balise.R_
Tests statiques réalisés uniquement sur 1 balise. 
Ces tests permettent de déterminer l'erreur de localisation du GPS et de choisir les paramètres qui y sont corrélés et qui constituraient un critère pour déterminer des seuils au delà desquels les points GPS d'un suivi sont considérés comme faux.    
Pour ornitella 30g : pas de paramètres type HDOP ou nombre sat retenus pour le moment (faiblement corrélés).    
__LE = 4 m__


## II – Formatage et nettoyage des données de suivi

__1.	Télécharger les données sur le site d’Ornitella et le mettre dans 1 dossier correspondant à l’individu (ex :_Houmous_)__     
- 1 fichier .csv par période par balise     
- attention heure de début et de fin (se rapprocher le + possible)    
- numéroter les fichiers dans l’ordre chronologique   

__2.	Appliquer les traitements__   
_Script Fusion et nettoyage.R_
- tous les fichiers du dossier _Houmous_ sont sélectionnés et traités en même temps
- suppression des points sur les 12h après équipement individus   
- ajout colonne ‘Name’ et ‘RecOrig’   
- suppression doublons et nuls (= pas de coordonnées)   
- calcul IDtraj : nouveau trajet quand + de 10h entre 2 points (environ 1 traj / nuit)    
- ajout des coordonnées en UTM    
- création d’un nouveau fichier brut : _Houmous_tot.csv_    

! ce fichier peut encore comporter des points dit 'aberrants', et ne différencie pas activité / repos



