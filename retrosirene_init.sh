# script de chargement des données complémentaires permettant de regénérer
# les fichiers SIRENE au plus proche du format de 2017

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

# population légale
in2csv Fichier_poplegale_6815.xls --sheet 2015 -K 7 > poplegale.csv
psql $DB -c "create table poplegale (`head poplegale.csv -n 1 | sed 's/,/ text,/g;s/$/ text/'`);"
psql $DB -c "\copy poplegale from poplegale.csv with (format csv, header true)"
psql $DB -c "alter table poplegale alter pmun15 type numeric USING pmun15::numeric; create index on poplegale (com);"
TCD="01=49 02=99 03=149 03=199 05=349 06=299 07=399 08=499 11=699 12=999 13=1499 14=1999 15=2499 16=2999 17=3999 18=4999 21=6999 22=9999 31=14999 32=19999 41=24999 42=29999 43=39999 44=49999 51=69999 52=99999 61=149999 62=199999 71=299999 72=499999 73=1499999 80=1500000"
for t in $TCD
do
  psql $DB -c "UPDATE poplegale SET tcd ='`echo $t | sed 's/=/\x27 WHERE tcd is null and pmun15<=/'`;"
done
psql $DB -c "UPDATE poplegale SET tcd = '80' where com like '75%';"

