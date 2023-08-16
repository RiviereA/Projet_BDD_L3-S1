# Projet de Base de Données (L3 Semestre 1)

Projet ayant pour but de conceptualiser une base de donnée fonctionnelle pour un système de gestion de location de vélo. 

## Les tables

Notre diagramme de classe dispose de onze tables distinctes. 

les tables STATION, BORNE et ATTACHE permettent de modéliser le comportement d'une station classique.

La table UTILISATEUR contient les données liées aux utilisateurs qui sont liées aux tables ABONNEMENT et SOUSCRIPTION qui gèrent les abonnements.

Les tables VOYAGE, VELOVOYAGE, et CAMIONNETTE modélise le système de transport de vélos entre les stations afin de les équilibrer.

**STATION**(***idstation***, secteur, etat, nbattache, bonus)

**BORNE**(***idborne***, * *idstation* *)

**ATTACHE**(***idattache***, idvelo, * *idstation* *, voyant)

**VELO**(***idvelo***, * *idstation* *, etat)

**UTILISATEUR**(***idutilisateur***, nom, prenom, solde, daten)

**ABONNEMENT**(***idabonnement***, prix, duree, description)

**SOUSCRIPTION**(idutilisateur, idabonnement, dateouv, datefin)

**LOCATION**(***idlocation***, idvelo, * *idutilisateur* *, dated, datef, * *idstationdepart* *, * *idstationarrive* *, prix)

**CAMIONNETTE**(***idcamionnette***, nbvelomax)

**VOYAGE**(***idvoyage***, * *idcamionnette* *, datevoyage, * *idstationdepart* *, * *idstationarrive* *)

**VELOVOYAGE**(***idvelo, idvoyage***)

Légende :
* ***Clés primaires***
* * *Clés étrangères* *

## Les vues

Dans ce projet existe cinq vues :
* La vue **ABONNEMENTUTILISATEUR** qui affiche le nom et le prénom de l'utilisateur, ainsi que le prix, la date d'ouverture et le date de fin des abonnements, cette vue à pour but de mettre à disposition des conseillers les informations sur les utilisateurs et leurs abonnements.
* La vue **LOCATIONUTILISATEUR** affiche l'id, le nom et prénom de l'utilisateur, ainsi que les informations sur les locations. Cette vue à pour but de rendre accessible pour les conseillers les informations sur les utilisateurs et les différentes locations faites.
* La vue **LOCATIONSTATION** affiche les stations de départ et le nombre de locations effectuées à chaque station. Cette vue permettra à un statisticien d'avoir accès à ses données pour entre autres optimiser le nombre de places disponibles dans les stations.
* La vue **VELOAQUAI** affiche le nombre de vélos disponibles dans chaque station, et permettra à l'utilisateur de savoir en temps réel s'il peut ou non avoir accès à un vélo à une station donnée.
* La vue **TRANSPORTEUR** affiche le nombre de vélo et les places disponibles pour chaque station, permettant aux transporteurx de savoir à quel endroit effectuer leurs voyages.
Toutes ses vues sont en * *READ ONLY* * pour éviter des actions frauduleuses des utilisateurs ou du personnel de l'entreprise.

## Les fonctionnalités

Huit triggers se charge de préserver l'intégrité du système et permettent notamment d'empêcher certaines insertions ou modifications dans la base de données.
* Le trigger **TUI_VELO** se déclenche avant une insertion ou une mise à jour dans la table **VELO**. Si le vélo concerné est en réparation ou en cours d’utilisation mais que celui-ci est toujours lié à une station, alors on lève un erreur.
* Le trigger **TUI_STATION_FERME** se déclenche avant une insertion ou une mise à jour dans la table **VELO**. Si le vélo est lié à une station, mais que celle-ci est fermé, alors on lève un erreur.
* Le trigger **TUI_VELO_ATTACHE** se déclenche avant une insertion ou une mise à jour dans la table **ATTACHE**. Si un vélo est lié à une attache, on vérifie si la station lié à l’attache est la même que pour le vélo, si ce n’est pas le cas alors on lève une erreur.
* Le trigger **TUI_ATTACHE** se déclenche avant une insertion ou une mise à jour dans la table **ATTACHE**. On vérifie l’on est en train d’attacher un vélo à une attache dont le voyant est rouge, si c’est le cas alors on lève un erreur.
* Le trigger **TI_ATTACHE** se déclenche uniquement après une insertion dans la table **ATTACHE**. Celui-ci va mettre à jour le nombre total d’attaches de la station pour laquelle on a ajouté l’attache.
* Le trigger **TD_ATTACHE** se déclenche uniquement après une suppression dans la table **ATTACHE**. Celui-ci va mettre à jour le nombre total d’attaches de la station à laquelle appartenait l’attache supprimé.
* Le trigger **TI_LOCATION** se déclenche avant une insertion dans la table **LOCATION**. Il lèvera une erreur si l’on cherche à louer un vélo depuis une station qui est fermé.
* Le trigger **TI_SOUSCRIPTION** se déclenche à la place d’une insertion dans la vue **TEMP_SOUSCRIPTION** qui est une copie de la table **SOUSCRIPTION**. Ce trigger aura pour effet de faire l’insertion dans la table SOUSCRIPTION en calculant la date à laquelle abonnement prendra fin en partant de la date de souscription et en y rajoutant 365 jours.

Plusieurs programme PL/SQL ont également été réalisés, se présentant sous la forme de procédures pouvant être exécutées par l’utilisateur pour effectuer certaines actions affectant la base de données. Parmi les procédure créées figure notamment :

* La procédure ***fermeStation***, qui permet de fermer une station dont on donne l’id en paramètres. Cela se traduit par le passage de l’état de la station à Ferme, et au passage des voyants de toutes les attaches de la station à rouge.
* La procédure ***louerVelo** qui, à partir de l’id du vélo choisit et de l’utilisateur, va mettre à jour les données de l’attache et du vélo, et va également insérer un ligne dans la table **LOCATION**, en prenant notamment en compte la date et l’heure à laquelle l’utilisateur à louer le vélo.
* La procédure ***deposeVelo*** qui partir de l’id de la location et de celui de la station, va vérifier s’il reste des attaches de disponible, si c’est le cas on calcule le temps qui s’est écoulé entre la location et la restitution du vélo et ainsi calculé le prix de la location puis mettre à jour les informations dans les tables **ATTACHE**, **VELO** et **LOCATION**.