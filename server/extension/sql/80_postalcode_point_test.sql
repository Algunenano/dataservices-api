-- Make sure dbs are clean
DELETE FROM global_postal_code_points;
DELETE FROM country_decoder;
DELETE FROM available_services;
DELETE FROM admin0_synonyms;

-- Check that the public function is callable, even with no data
-- It should return NULL
SELECT cdb_geocoder_server.geocode_postalcode_point(session_user, txid_current(), '03204');

-- Insert dummy data into ip_address_locations
INSERT INTO global_postal_code_points (the_geom, iso3, postal_code, postal_code_num) VALUES (
  '0101000020E61000000000000000E040408036B47414764840',
  'ESP',
  '03204',
  3204
);

INSERT INTO country_decoder (iso3, synonyms) VALUES (
  'ESP',
  Array['spain', 'Spain', 'ESP']
);

INSERT INTO available_services (adm0_a3, admin0, postal_code_points, postal_code_polygons) VALUES (
  'ESP',
  't',
  't',
  't'
);

INSERT INTO admin0_synonyms (adm0_a3, name, name_, rank) VALUES (
  'ESP',
  'Spain',
  'spain',
  3
);

-- This should return the polygon inserted above
SELECT cdb_geocoder_server.geocode_postalcode_point(session_user, txid_current(), '03204');

SELECT cdb_geocoder_server.geocode_postalcode_point(session_user, txid_current(), '03204', 'spain');

-- Clean dbs
DELETE FROM global_postal_code_points;
DELETE FROM country_decoder;
DELETE FROM available_services;
DELETE FROM admin0_synonyms;
