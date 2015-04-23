/* 
Requête permettant de générer les DEE au format INPN : 
inpn.mnhn.fr/docs/standard/standardsinpoccurrencetaxonv1.pdf 

nécessite de gérer les lots de données : https://github.com/mathieubossaert/scripts_sql_sicen/blob/dev/lots_de_donnees.sql
*/

SELECT row_number() OVER (ORDER BY lpad(saisie_observation.id_obs::text, 7, '0'::text)) AS gid, 
        -- à adapter selon les valeurs de votre enum saisie_observation.determination
        CASE saisie_observation.determination::text
            WHEN 'Vu'::text THEN 'te'::text
            WHEN 'Entendu'::text THEN 'te'::text
            WHEN 'Indice de présence'::text THEN 'te'::text
            WHEN 'Cadavre'::text THEN 'te'::text
            WHEN 'Capture'::text THEN 'te'::text
            WHEN 'Collection'::text THEN 'Co'::text
            WHEN 'Littérature'::text THEN 'Li'::text
            ELSE 'te'::text
        END AS statutsource, 
        CASE saisie_observation.determination::text
            WHEN 'Littérature'::text THEN 'à préciser'::text
            ELSE NULL::text
        END AS referencebiblio, 
    lpad(lot_donnee.id_lot::text, 4, '0'::text) AS jddid, 
    --le code idcnp de votre BDD, s'il existe
    'SICEN-LR:00-175'::text AS jddcode, 
    lpad(saisie_observation.id_obs::text, 7, '0'::text) AS identifiantorigine, 
    NULL::text AS identifiantpermanent, 
        CASE
            -- Privé si lot donnée "bénévolat" -> à adapter
            WHEN lot_donnee.libelle::text ~~* 'bénévolat%'::text THEN 'Pr'::text
            -- NSP si études "non mentionnée" ou "à préciser" -> à adapter
            WHEN saisie_observation.id_etude = ANY (ARRAY[39, 51]) THEN 'NSP'::text
            ELSE 'Ac'::text
        END AS dspublique, 
    NULL::text AS codeidcnpdispositif, 
    'CEN L-R'::text AS organismestandard, -- à adapter à votre structure
        CASE
            WHEN lower(saisie_observation.type_effectif) = 'absence'::text THEN 'No'::text -- si vous gérer la donnée d'absence comme un type d'effectif
            ELSE 'Pr'::text
        END AS statutobservation, 
    btrim(concat(saisie_observation.nom_vern, ' / ', saisie_observation.nom_complet), ' / '::text) AS nomcite, 
    saisie_observation.cd_nom::integer AS cdnom, 
    taxref.cd_ref::integer AS cdref, 'non'::text AS sensible, 
    COALESCE(saisie_observation.effectif, saisie_observation.effectif_min, 1::bigint)::integer AS denombrementmin, 
    COALESCE(saisie_observation.effectif, saisie_observation.effectif_max)::integer AS denombrementmax, 
        CASE
            WHEN saisie_observation.type_effectif ~~* ANY (ARRAY['abondance%'::text, 'classe%'::text]) THEN 'Es'::text -- A adapter pour vos types d'effectifs correspondant à des estimations
            ELSE 'Co'::text
        END AS typedenombrement, 
        CASE
            WHEN saisie_observation.type_effectif IS NOT NULL THEN 'In'::text
            ELSE NULL::text
        END AS objetdenombrement, 
        CASE
            WHEN saisie_observation.observateur = '20'::text THEN 'NSP'::text -- Remplacer 20 par l'id de votre observateur anonyme ou inconnu
            ELSE md.liste_nom_auteur(saisie_observation.observateur, ', '::text)
        END AS identiteobservateur, 
        CASE md.liste_nom_structure(saisie_observation.structure, ', '::text)
            WHEN 'Pas de structure'::text THEN 'indépendant'::text
            ELSE md.liste_nom_structure(saisie_observation.structure, ', '::text)
        END AS organismeobservateur, 
    'CEN L-R'::text AS organismegestionnairedonnees, 
        CASE
            WHEN saisie_observation.observateur <> '20'::text THEN md.liste_nom_auteur(saisie_observation.observateur, ', '::text)
            ELSE NULL::text
        END AS determinateur, 
    btrim(concat(validateur.nom, ' ', validateur.prenom)) AS validateur, 
    saisie_observation.remarque_obs AS commentaire, 
    COALESCE(saisie_observation.date_obs, saisie_observation.date_debut_obs) AS datedebut, 
    COALESCE(saisie_observation.date_obs, saisie_observation.date_fin_obs) AS datefin, 
    NULL::time without time zone AS heuredebut, 
    NULL::time without time zone AS heurefin, 
    NULL::date AS datedeterminationobs, 
    saisie_observation.elevation::numeric AS altitudemin, 
    saisie_observation.elevation::numeric AS altitudemax, 
    NULL::numeric AS profondeurmin, NULL::numeric AS profondeurmax, 
    NULL::text AS codehabitat, NULL::text AS refhabitat, 
    st_asgml(saisie_observation.geometrie) AS geometrie, 
        --A adpater au contenu de votre enum saisie_observation."precision"
        CASE saisie_observation."precision"
            WHEN 'GPS'::saisie.enum_precision THEN 10
            WHEN '0 à 10m'::saisie.enum_precision THEN 10
            WHEN '10 à 100m'::saisie.enum_precision THEN 100
            WHEN '100 à 500m'::saisie.enum_precision THEN 500
            ELSE 1000
        END AS "precision", 
        CASE
            WHEN st_geometrytype(saisie_observation.geometrie) ~~* '%POINT%'::text THEN 'St'::text
            WHEN st_geometrytype(saisie_observation.geometrie) ~~* '%POLYGON%'::text OR st_geometrytype(saisie_observation.geometrie) ~~* '%LINE%'::text THEN 'In'::text
            ELSE 'NSP'::text
        END AS natureobjetgeo, 
    COALESCE(saisie_observation.code_insee, commune.code_insee::text) AS codecommune, 
    commune.nom AS nomcommune, sites_cen_inpn_2014.id_mnhn::text AS codeen, 
    NULL::text AS typeen, NULL::text AS codemaille, 
        CASE
            WHEN st_geometrytype(saisie_observation.geometrie) ~~* '%Point%'::text THEN st_x(saisie_observation.geometrie::geometry(Point,2154))
            ELSE st_x(st_centroid(saisie_observation.geometrie))
        END AS st_x, 
        CASE
            WHEN st_geometrytype(saisie_observation.geometrie) ~~* '%Point%'::text THEN st_y(saisie_observation.geometrie::geometry(Point,2154))
            ELSE st_y(st_centroid(saisie_observation.geometrie))
        END AS st_y
   FROM saisie.saisie_observation
   JOIN inpn.taxref_v8 taxref USING (cd_nom)
   JOIN ign_bd_topo.commune ON st_intersects(commune.geometrie, saisie_observation.geometrie)
   -- nécessite d'intégrer la couche des sites envoyée par Julien dans la table referentiels_divers.sites_cen_inpn_2014
   LEFT JOIN referentiels_divers.sites_cen_inpn_2014 ON st_intersects(sites_cen_inpn_2014.geometrie, saisie_observation.geometrie)
   LEFT JOIN md.lot_donnee ON saisie_observation.id_etude = lot_donnee.id_etude AND saisie_observation.id_protocole = lot_donnee.id_protocole AND ((
CASE
WHEN st_geometrytype(saisie_observation.geometrie) ~~* '%Point%'::text THEN 'point'::text
WHEN st_geometrytype(saisie_observation.geometrie) ~~* '%LineString%'::text THEN 'ligne'::text
WHEN st_geometrytype(saisie_observation.geometrie) ~~* '%Polygon%'::text THEN 'perimetre'::text
ELSE NULL::text
END || '_'::text) || 
CASE saisie_observation.regne
    WHEN 'Plantae'::text THEN 'espece'::text
    WHEN 'Animalia'::text THEN 'espece'::text
    WHEN 'Fungi'::text THEN 'espece'::text
    WHEN 'Habitat'::text THEN 'habitat'::text
    ELSE NULL::text
END) = lot_donnee.type_donnee::text
   LEFT JOIN md.personne validateur ON saisie_observation.validateur = validateur.id_personne
  WHERE taxref.cd_nom::text ~ '^[\d+]'::text -- on enlève les taxons créé pour les besoins internes, qui ne contiennent pas que des chiffres
  AND (saisie_observation.regne = ANY (ARRAY['Animalia'::text, 'Plantae'::text, 'Fungi'::text])) 
  -- on filtre les données que l'on peut diffuser pour cet export 
  AND (md.liste_nom_structure(saisie_observation.structure, ', '::text) = ANY (ARRAY['CEN LR'::text, 'Pas de structure'::text])) 
  -- on enlève les atxons non présents dans taxref
  AND saisie_observation.cd_nom <> '000000'::text;
