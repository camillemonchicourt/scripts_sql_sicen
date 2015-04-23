/* Création de la table md.lot_donnee */

CREATE TABLE md.lot_donnee
(
  id_lot serial NOT NULL,
  libelle character varying(254),
  id_etude integer,
  type_donnee md.enum_type_donnee,
  resume text,
  description_genealogie text,
  echelle_utilisation text,
  licence character varying,
  limitation_acces_public boolean,
  qualite_thematique text,
  id_protocole integer,
  code character varying,
  responsable_code_personne character varying,
  CONSTRAINT pk_lot_donnee PRIMARY KEY (id_lot),
  CONSTRAINT fk_etude_id_protocole_reference_protocole FOREIGN KEY (id_protocole)
      REFERENCES md.protocole (id_protocole) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_etude_lot_donnee_reference_etude FOREIGN KEY (id_etude)
      REFERENCES md.etude (id_etude) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION,
  CONSTRAINT fk_responsable_code_personne_references_personne_code_personne FOREIGN KEY (responsable_code_personne)
      REFERENCES md.personne (code_personne) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "unique nom lot" UNIQUE (id_lot)
)
WITH (
  OIDS=FALSE
);

COMMENT ON TABLE md.lot_donnee
  IS 'Décrit les lots de données produits ou utilisé au CEN.';
  
/* On l'alimente Comme ceci */

INSERT INTO md.lot_donnee(
            libelle, id_etude, type_donnee, id_protocole)
SELECT concat(nom_etude,' ; ', libelle,' -> ',
CASE
    WHEN st_geometrytype(geometrie) ILIKE '%point' THEN 'points'
    WHEN st_geometrytype(geometrie) ILIKE '%string' THEN 'lignes'
    WHEN st_geometrytype(geometrie) ILIKE '%polygon' THEN 'polygones'
END, ' | ', CASE WHEN regne = 'Animalia' THEN 'faune' WHEN regne = 'Plantae' THEN 'flore' WHEN regne = 'Habitat' THEN 'habitats' END ) as libelle_lot, id_etude,
concat(
CASE
    WHEN st_geometrytype(geometrie) ILIKE '%point' THEN 'point'
    WHEN st_geometrytype(geometrie) ILIKE '%string' THEN 'ligne'
    WHEN st_geometrytype(geometrie) ILIKE '%polygon' THEN 'perimetre'
END, '_', CASE WHEN regne = 'Animalia'OR regne = 'Plantae' OR regne = 'Fungi' THEN 'espece' WHEN regne = 'Habitat' THEN 'habitat' END )::md.enum_type_donnee AS type_donnee
,id_protocole
  FROM saisie.saisie_observation
  JOIN md.etude USING(id_etude)
  JOIn md.protocole USING(id_protocole)
  /* seulement les lots non déjà présents dans la table */
  WHERE (id_etude, concat(
CASE
    WHEN st_geometrytype(geometrie) ILIKE '%point' THEN 'point'
    WHEN st_geometrytype(geometrie) ILIKE '%string' THEN 'ligne'
    WHEN st_geometrytype(geometrie) ILIKE '%polygon' THEN 'perimetre'
END, '_', CASE WHEN regne = 'Animalia'OR regne = 'Plantae' OR regne = 'Fungi' THEN 'espece' WHEN regne = 'Habitat' THEN 'habitat' END )::md.enum_type_donnee , id_protocole) NOT IN (SELECT id_etude, type_donnee, id_protocole FROM md.lot_donnee)
GROUP BY regne, st_geometrytype(geometrie), nom_etude, libelle, id_etude, id_protocole
ORDER BY 1;
