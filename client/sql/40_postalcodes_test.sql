-- Add to the search path the schema
SET search_path TO public,cartodb,cdb_geocoder_client;

-- Mock the server functions
CREATE OR REPLACE FUNCTION cdb_geocoder_server.cdb_geocode_postalcode_polygon(username text, postal_code text, country_name text)
RETURNS Geometry AS $$
BEGIN
  RAISE NOTICE 'cdb_geocoder_server.cdb_geocode_postalcode_polygon invoked with params (%, %, %)', username, postal_code, country_name;
  RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION cdb_geocoder_server.cdb_geocode_postalcode_point(username text, postal_code text, country_name text)
RETURNS Geometry AS $$
BEGIN
  RAISE NOTICE 'cdb_geocoder_server.cdb_geocode_postalcode_point invoked with params (%, %, %)', username, postal_code, country_name;
  RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

-- Exercise the public and the proxied function
SELECT cdb_geocode_postalcode_polygon('03204', 'Spain');
SELECT cdb_geocode_postalcode_point('03204', 'Spain');
