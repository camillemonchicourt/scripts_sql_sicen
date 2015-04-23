CREATE OR REPLACE FUNCTION md.liste_nom_auteur(text, text)
  RETURNS text AS
$BODY$
DECLARE
    var_liste_code_personne ALIAS for $1;
    separateur ALIAS for $2;
BEGIN
RETURN string_agg(nom || ' ' || prenom,separateur) FROM (SELECT regexp_split_to_table(var_liste_code_personne,'&')::integer as id_personne) t
LEFT JOIN md.personne USING(id_personne);
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;
