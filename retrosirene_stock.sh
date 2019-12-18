#! /bin/bash

# script de chargement et export permettant de regénérer
# les fichiers stocks mensuels SIRENE au plus proche du format de 2017

DB=sirene

wget -N http://files.data.gouv.fr/insee-sirene/StockUniteLegale_utf8.zip
wget -N http://files.data.gouv.fr/insee-sirene/StockUniteLegaleHistorique_utf8.zip
wget -N http://files.data.gouv.fr/insee-sirene/StockEtablissementHistorique_utf8.zip
wget -N http://data.cquest.org/geo_sirene/v2019/last/StockEtablissement_utf8_geo.csv.gz

# création de la table SIREN (entreprises)
psql $DB -c "create table siren_temp (`unzip -p StockUniteLegale_utf8.zip | head -n 1 | sed 's/,/ text,/g;s/$/ text/'`);"
unzip -p StockUniteLegale_utf8.zip | psql $DB -c "\copy siren_temp from stdin with (format csv, header true)"
# optimisation: clustering de la table sur SIREN
psql $DB -c "drop table if exists siren cascade; create table siren as (select * from siren_temp order by siren); drop table siren_temp;"
# création d'un index rapide (BRIN) sur SIREN
psql $DB -c "create index on siren using brin (siren);"

# création de la table des établissements
psql $DB -c "drop table if exists siret_temp; create table siret_temp (`zcat StockEtablissement_utf8_geo.csv.gz | head -n 1 | sed 's/,/ text,/g;s/$/ text/'`);"
zcat StockEtablissement_utf8_geo.csv.gz | psql $DB -c "\copy siret_temp from stdin with (format csv, header true)"
# optimisation: clustering de la table sur SIRET
psql $DB -c "drop table if exists siret cascade; create table siret as (select * from siret_temp order by siret); drop table siret_temp"
# création d'un index rapide (BRIN) sur SIREN et SIRET
psql $DB -c "create index on siret using brin (siren); create index on siret using brin (siret);"

# création des tables de variables historisées
psql $DB -c "drop table if exists siren_histo cascade; create table siren_histo (`unzip -p StockUniteLegaleHistorique_utf8.zip | head -n 1 | sed 's/,/ text,/g;s/$/ text/'`);"
unzip -p StockUniteLegaleHistorique_utf8.zip | psql $DB -c "\copy siren_histo from stdin with (format csv, header true)"
psql $DB -c "create index on siren_histo (siren);"

psql $DB -c "drop table if exists siret_histo cascade; create table siret_histo (`unzip -p StockEtablissementHistorique_utf8.zip | head -n 1 | sed 's/,/ text,/g;s/$/ text/'`);"
unzip -p StockEtablissementHistorique_utf8.zip | psql $DB -c "\copy siret_histo from stdin with (format csv, header true)"
psql $DB -c "create index on siret_histo (siren); create index on siret_histo (siret);"

# création de la vue sirene2017
psql $DB < retrosirene.sql

# export des établissements selon le modèle 2017
psql $DB -c "copy (select * from sirene2017 where ind_publipo = 'A') to STDOUT with (format csv, header true);" | gzip -9 > etablissements_actifs.csv.gz
psql $DB -c "copy (select * from sirene2017 where ind_publipo = 'F') to STDOUT with (format csv, header true);" | gzip -9 > etablissements_fermes.csv.gz

# upload
DIR=$(date -r StockUniteLegale_utf8.zip +%Y-%m)
rsync etablissements_*.csv.gz root@192.168.0.72:/local-zfs/opendatarchives/data.cquest.org/geo_sirene/$DIR -av
ssh root@192.168.0.72 "cd /local-zfs/opendatarchives/data.cquest.org/geo_sirene; cp last/LISEZMOI.txt $DIR; rm -f last; ln -f -s $DIR last"

exit

# Extraction de fichiers dérivés utiles
# prénoms
psql $DB -c "\copy (select prenom, sum(nb) from (select prenom1unitelegale as prenom, count(*) as nb from siren group by 1 union select prenom2unitelegale as prenom, count(*) as nb from siren group by 1 union select prenom3unitelegale as prenom, count(*) as nb from siren group by 1 union select prenom4unitelegale as prenom, count(*) as nb from siren group by 1) as p where prenom  ~ '^[A-Z]{2,}$' AND prenom ~ '[AEIOUY]' group by 1 order by 1) to prenom.csv with (format csv, header true)"

# patronymes
psql $DB -c "\copy (select regexp_replace(replace(nomunitelegale,'-',' '),' +',' ','g') as patronyme, count(*) from siren where prenom1unitelegale is not null and nomunitelegale is not null group by 1 order by 1) to patronymes.csv with (format csv , header true)"
