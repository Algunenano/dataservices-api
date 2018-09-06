\set VERBOSITY terse
SET client_min_messages TO warning;
SET search_path TO public,cartodb,cdb_dataservices_client;

-- Mock the server functions to raise exceptions
CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_geocode_street_point (username text, orgname text, appname text, searchtext text, city text DEFAULT NULL, state_province text DEFAULT NULL, country text DEFAULT NULL)
RETURNS Geometry AS $$
BEGIN
  RAISE EXCEPTION 'Not enough quota or any other exception whatsoever.';
  RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_isodistance(username text, orgname text, appname text, source geometry, mode text, range integer[], options text[] DEFAULT ARRAY[]::text[])
RETURNS SETOF isoline AS $$
BEGIN
  RAISE EXCEPTION 'Not enough quota or any other exception whatsoever.';
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_route_point_to_point (username text, orgname text, appname text, origin geometry(Point, 4326), destination geometry(Point, 4326), mode TEXT, options text[] DEFAULT ARRAY[]::text[], units text DEFAULT 'kilometers')
RETURNS cdb_dataservices_client.simple_route AS $$
DECLARE 
  ret cdb_dataservices_client.simple_route;
BEGIN
  RAISE EXCEPTION 'Not enough quota or any other exception whatsoever.';

  -- This code shall never be reached
  SELECT NULL, 5.33, 100 INTO ret;
  RETURN ret;
END;
$$ LANGUAGE 'plpgsql';



-- Use regular user role
SET ROLE test_regular_user;

-- Exercise the exception safe and the proxied functions
SELECT _cdb_geocode_street_point_exception_safe('One street, 1');
SELECT * FROM _cdb_isodistance_exception_safe('POINT(-3.70568 40.42028)'::geometry, 'walk', ARRAY[300]::integer[]);
SELECT * FROM _cdb_route_point_to_point_exception_safe('POINT(-3.70237112 40.41706163)'::geometry,'POINT(-3.69909883 40.41236875)'::geometry, 'car', ARRAY['mode_type=shortest']::text[]);
