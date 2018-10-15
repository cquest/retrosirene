CREATE OR REPLACE VIEW sirene2017 AS
SELECT
  s.siren,
  e.nic,
  coalesce(e.denominationusuelleetablissement, e.enseigne1etablissement, e.enseigne2etablissement, e.enseigne3etablissement, s.nomusageunitelegale, s.nomunitelegale) as l1_normalise,
  '' as l2_normalisee,
  '' as l3_normalisee,
  e.geo_l4 as l4_normalisee,
  coalesce(e.distributionspecialeetablissement,e.geo_l5) as l5_normalisee,
  format('%s %s', e.codepostaletablissement, e.libellecommuneetablissement) as l6_normalisee,
  e.libellepaysetrangeretablissement as l7_normalisee,
  coalesce(e.denominationusuelleetablissement, e.enseigne1etablissement, e.enseigne2etablissement, e.enseigne3etablissement, s.nomusageunitelegale, s.nomunitelegale) as l1_declaree,
  '' as l2_declaree,
  '' as l3_declareeee,
  e.geo_l4 as l4_declaree,
  coalesce(e.distributionspecialeetablissement,e.geo_l5) as l5_declaree,
  format('%s %s', e.codepostaletablissement, e.libellecommuneetablissement) as l6_declaree,
  e.libellepaysetrangeretablissement as l7_declaree,
  e.numerovoieetablissement as numvoie,
  e.indicerepetitionetablissement as indrep,
  e.typevoieetablissement as typvoie,
  e.libellevoieetablissement as libvoie,
  e.codepostaletablissement as codpos,
  e.codecedexetablissement as cedex,
  c.reg as rpet,
  r.nccenr as libreg,
  c.dep as depet,
  c.ar as arronet,
  c.ct as ctonet,
  c.com as comet,
  replace(format('%s %s',c.ncc, c.artmaj),'-',' ') as libcom,
  g.dep as du,
  g.tuu2015 as tu,
  g.uu2010 as uu,
  g.epci as epci,
  null as tcd,
  g.ze2010 as zemet,
  case when e.etablissementsiege = 'true' then '1' else '0' end as siege,
  e.enseigne1etablissement as enseigne,
  null as ind_publipo,
  null as diffcom,
  left(replace(e.datedebut,'-',''),6) as amintret,
  null as natetab,
  null as libnatetab,
  replace(e.activiteprincipaleetablissement,'.','') as apet700,
  a_et.libelle as libapet700,
  null dapet,
  e.trancheeffectifsetablissement as tefet,
  null as libtefet,
  null as efetcent,
  null as defet,
  null as origine,
  left(replace(e.datecreationetablissement,'-',''),8) as dcret,
  left(replace(e.datedebut,'-',''),8) as ddebact,
  null as activnat,
  null as lieuact,
  null as actisurf,
  null as saisonat,
  null as modet,
  null as prodet,
  null as prodpart,
  null as auxilt,
  coalesce(regexp_replace(s.nomunitelegale||'*'||s.prenom1unitelegale||'/'||coalesce(s.prenom2unitelegale,'')||'/'||coalesce(s.prenom3unitelegale,'')||'/'||coalesce(s.prenom4unitelegale,'')||'/','//+','/'), e.enseigne1etablissement, s.denominationunitelegale) as nomen_long,
  s.sigleunitelegale as sigle,
  s.nomunitelegale as NOM,
  s.prenom1unitelegale as PRENOM,
  case when s.sexeunitelegale = 'M' then 'MONSIEUR' when s.sexeunitelegale = 'F' then 'MADAME' else null end as CIVILITE,
  s.identifiantassociationunitelegale as RNA,
  s.nicsiegeunitelegale as NICSIEGE,
  c_siege.reg as RPEN,
  siege.codecommuneetablissement as DEPCOMEN,
  null as ADR_MAIL,
  categoriejuridiqueunitelegale as NJ,
  null as LIBNJ,
  replace(activiteprincipaleunitelegale,'.','') as APEN700,
  a_si.libelle as LIBAPEN,
  null as DAPEN,
  null as APRM,
  null as ESS,
  null as DATEESS,
  s.trancheeffectifsunitelegale as TEFEN,
  null as LIBTEFEN,
  null as EFENCENT,
  s.anneeeffectifsunitelegale as DEFEN,
  categorieentreprise as CATEGORIE,
  left(replace(s.datecreationunitelegale,'-',''),6) as DCREN,
  left(replace(s.datedebut,'-',''),6) as AMINTREN,
  null as MONOACT,
  null as MODEN,
  null as PRODEN,
  null as ESAANN,
  null as TCA,
  null as ESAAPEN,
  null as ESASEC1N,
  null as ESASEC2N,
  null as ESASEC3N,
  null as ESASEC4N,
  null as VMAJ,
  null as VMAJ1,
  null as VMAJ2,
  null as VMAJ3,
  e.datederniertraitementetablissement as DATEMAJ,
  e.latitude,
  e.longitude,
  e.geo_score,
  e.geo_type,
  e.geo_adresse,
  e.geo_id,
  e.geo_ligne,
  e.geo_l4,
  e.geo_l5
FROM siret e
JOIN siren s ON (e.siren=s.siren)
JOIN siret siege ON (siege.siret=s.siren||nicsiegeunitelegale)
LEFT JOIN activite a_et ON (a_et.nomenclature = e.nomenclatureactiviteprincipaleetablissement and a_et.code = e.activiteprincipaleetablissement)
LEFT JOIN activite a_si ON (a_si.nomenclature = nomenclatureactiviteprincipaleunitelegale and a_si.code = activiteprincipaleunitelegale)
LEFT JOIN cog c ON (e.codecommuneetablissement = c.depcom and c.actual='1')
LEFT JOIN cog c_siege ON (siege.codecommuneetablissement = c_siege.depcom and c_siege.actual='1')
LEFT JOIN cog_reg r ON (r.region = c.reg and c.actual='1')
LEFT JOIN geo_com g ON (g.codgeo = e.codecommuneetablissement);
