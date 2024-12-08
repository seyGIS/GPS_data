# GPS_data
cleaning and processing GPS data

# Notice : Traitement des données GPS Hérisson


## I – Choix des paramètres statiques 
_Voir GPS > Paramètres balises > Test_balise.R_
Tests statiques réalisés uniquement sur la balise n° 244201 
Pas de paramètres type HDOP ou nombre sat retenus pour le moment (faiblement corrélés) 
__LE = 4 m__

## II – Formatage et nettoyage des données 

__1.	Télécharger les données sur le site d’Ornitella et le mettre dans 1 dossier correspondant à l’individu (ex : _Houmous_) __
> 1 fichier .csv par période par balise 
> attention heure de début et de fin (se rapprocher le + possible) 
> numéroter les fichiers dans l’ordre chronologique

__2.	Script Fusion et nettoyage.R (dans _GPS > Suivis > Nettoyage_data_)__
> tous les fichiers du dossier _Houmous_ sont sélectionnés et traités en même temps
> suppression des points sur les 12h après équipement individus
> ajout colonne ‘Name’ et ‘RecOrig’
> suppression doublons et nuls 
> calcul IDtraj : nouveau trajet quand + de 10h entre 2 points (environ 1 traj / nuit)
> ajout des coordonnées en UTM 
> création d’un nouveau fichier brut : _Houmous_tot.csv_

! ce fichier comporte tous les points confondus : points aberrants, activité / repos



