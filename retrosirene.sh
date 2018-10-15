# script de chargement des données dans Postgresql permettant de regénérer
# les fichiers stocks SIRENE au plus proche du format de 2017
DB=$1

psql -c "CREATE DATABASE $db;"

cd data

# nomenclatures des activités
psql $DB -c "CREATE TABLE IF NOT EXISTS activite (nomenclature text, code text, libelle text); TRUNCATE activite;"

in2csv "NAP 1973_1993.xls" | csvcut -c NAP600,LIB_NAP600 | sed 's/^/NAP,/' > nap1973.csv
psql $DB -c "\copy activite from nap1973.csv with (format csv, header true)"

in2csv naf1993_liste_n5.xls -K 1 | sed 's/^/NAF1993,/' > naf1993.csv
psql $DB -c "\copy activite from naf1993.csv with (format csv, header true)"

in2csv naf2003_liste_n5.xls -K 1 | sed 's/^/NAFRev1,/' > naf2003.csv
psql $DB -c "\copy activite from naf2003.csv with (format csv, header true)"

in2csv naf2008_liste_n5.xls -K 2 | sed 's/^/NAFRev2,/' > naf2008.csv
psql $DB -c "\copy activite from naf2008.csv with (format csv, header true)"

psql $DB -c "CREATE INDEX activite_cluster ON activite (nomenclature, code); cluster activite using activite_cluster ;"


# cog communes
csvclean France2018.txt -t -e 'iso8859-1'
psql $DB -c "create table cog (`head France2018_out.csv -n 1 | sed 's/,/ text,/g;s/$/ text/'`);"
psql $DB -c "\copy cog from France2018_out.csv with (format csv, header true)"
psql $DB -c "alter table cog add depcom text; update cog set depcom = dep||com; create index on cog (depcom);"

# cog régions
csvclean reg2018.txt -t -e 'iso8859-1'
psql $DB -c "create table cog_reg (`head reg2018_out.csv -n 1 | sed 's/,/ text,/g;s/$/ text/'`);"
psql $DB -c "\copy cog_reg from reg2018_out.csv with (format csv, header true)"

# unités urbaines, EPCI, zone d'emploi, etc...
in2csv table-appartenance-geo-communes-18_V2.xls -K 5 > geo_com.csv
psql $DB -c "create table geo_com (`head geo_com.csv -n 1 | sed 's/,/ text,/g;s/$/ text/'`);"
psql $DB -c "\copy geo_com from geo_com.csv with (format csv, header true)"
psql $DB -c "create index on geo_com (codgeo);"

# natures juridiques
in2csv cj_juillet_2018.xls --sheet 'Niveau III' -K 3 > cj_juillet_2018.csv
psql $DB -c "create table nj (`head cj_juillet_2018.csv -n 1 | sed 's/,/ text,/g;s/$/ text/'`);"
psql $DB -c "\copy nj from cj_juillet_2018.csv with (format csv, header true)"
psql $DB -c "create index on nj (code);"


# création de la table SIREN (entreprises)
psql $DB -c "create table siren_temp (`unzip -p StockUniteLegale_utf8.csv | head -n 1 | sed 's/,/ text,/g;s/$/ text/'`);"
unzip -p StockUniteLegale_utf8.csv.zip | psql $DB -c "\copy siren_temp from stdin with (format csv, header true)"
# optimisation: clustering de la table sur SIREN
psql $DB -c "create table siren as (select * from siren_temp order by siren); drop table siren_temp;"
# création d'un index rapide (BRIN) sur SIREN
psql $DB -c "create index on siren using brin (siren);"

# création de la table des établissements
psql $DB -c "create table siret_temp (`zcat StockEtablissement_utf8_geo.csv.gz | head -n 1 | sed 's/,/ text,/g;s/$/ text/'`);"
zcat StockEtablissement_utf8_geo.csv.gz | psql $DB -c "\copy siret_temp from stdin with (format csv, header true)"
# optimisation: clustering de la table sur SIRET
psql $DB -c "create table siret as (select * from siret_temp order by siret); drop table siret_temp"
# création d'un index rapide (BRIN) sur SIREN et SIRET
psql $DB -c "create index on siret using brin (siren); create index on siret using brin (siret);"

# création des tables de variables historisées
psql $DB -c "create table siren_histo (`unzip -p stockunitelegalehistorique-utf8.zip | head -n 1 | sed 's/,/ text,/g;s/$/ text/'`);"
unzip -p stockunitelegalehistorique-utf8.zip | psql $DB -c "\copy siren_histo from stdin with (format csv, header true)"
psql $DB -c "create index on siren_histo (siren);"
psql $DB -c "create table siret_histo (`unzip -p stocketablissementhistorique-utf8.zip | head -n 1 | sed 's/,/ text,/g;s/$/ text/'`);"
unzip -p stocketablissementhistorique-utf8.zip | psql $DB -c "\copy siret_histo from stdin with (format csv, header true)"
psql $DB -c "create index on siret_histo (siren); create index on siret_histo (siret);"


# création de la vue sirene2017
psql $DB < retrosirene.sql

# export des établissements selon le modèle 2017
psql $DB -c "\copy (select * from sirene2017 where ind_publipo = 'A') to 'etablissements_actifs.csv' with (format csv, header true);"
psql $DB -c "\copy (select * from sirene2017 where ind_publipo = 'F') to 'etablissements_fermes.csv' with (format csv, header true);"


exit

# Extraction de fichiers dérivés utiles
# prénoms
psql $DB -c "\copy (select prenom, sum(nb) from (select prenom1unitelegale as prenom, count(*) as nb from siren group by 1 union select prenom2unitelegale as prenom, count(*) as nb from siren group by 1 union select prenom3unitelegale as prenom, count(*) as nb from siren group by 1 union select prenom4unitelegale as prenom, count(*) as nb from siren group by 1) as p where prenom  ~ '^[A-Z]{2,}$' AND prenom ~ '[AEIOUY]' group by 1 order by 1) to prenom.csv with (format csv, header true)"

# patronymes
psql $DB -c "\copy (select regexp_replace(replace(nomunitelegale,'-',' '),' +',' ','g') as patronyme, count(*) from siren where prenom1unitelegale is not null and nomunitelegale is not null group by 1 order by 1) to patronymes.csv with (format csv , header true)"
