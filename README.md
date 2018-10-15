# Rétrocompatibilité des fichiers SIRENE 2019 / 2017

Depuis octobre 2018, l'INSEE diffuse les fichiers de la base SIRENE avec un nouveau modèle de données.

Ces scripts permettent de regénérer des fichiers au plus proche de l'ancien modèle.

## Outils utilisés

- Postgresql (>= 9.5)
- csvkit (https://csvkit.readthedocs.io/en/stable/)
- commandes bash classiques: unzip, zcat, sed

## retrosirene.sh

`./retrosirene.sh <nom_base_postgresql>`

Ce script charge dans la base Postgresql:
- les nomenclatures d'activité NAP/NAF (1973, 1993, 2003, 2008)
- le Code Officiel Géographique (communes et régions)
- la table d'appartenance des communes à différents zonages (EPCI, Unités Urbaines, etc)
- les données stock SIRENE selon le nouveau modèle

Il créé ensuite une vue "sirene2017" s'approchant du modèle de donnée de 2017.
