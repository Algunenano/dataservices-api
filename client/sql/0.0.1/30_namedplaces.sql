--
-- Public geocoder API function
--
-- These are the only ones with permissions to publicuser role
-- and should also be the only ones with SECURITY DEFINER

---- geocode_namedplace_point(city_name text)
CREATE OR REPLACE FUNCTION cdb_geocoder_client.geocode_namedplace_point(city_name text)
RETURNS Geometry AS $$
DECLARE
  ret Geometry;
BEGIN
  SELECT cdb_geocoder_client._geocode_namedplace_point(session_user, txid_current(), city_name) INTO ret;
  RETURN ret;
END;
$$ LANGUAGE 'plpgsql' SECURITY DEFINER;

---- geocode_namedplace_point(city_name text, country_name text)
CREATE OR REPLACE FUNCTION cdb_geocoder_client.geocode_namedplace_point(city_name text, country_name text)
RETURNS Geometry AS $$
DECLARE
  ret Geometry;
BEGIN
  SELECT cdb_geocoder_client._geocode_namedplace_point(session_user, txid_current(), city_name, country_name) INTO ret;
  RETURN ret;
END;
$$ LANGUAGE 'plpgsql' SECURITY DEFINER;

---- geocode_namedplace_point(city_name text, admin1_name text, country_name text)
CREATE OR REPLACE FUNCTION cdb_geocoder_client.geocode_namedplace_point(city_name text, admin1_name text, country_name text)
RETURNS Geometry AS $$
DECLARE
  ret Geometry;
BEGIN
  SELECT cdb_geocoder_client._geocode_namedplace_point(session_user, txid_current(), city_name, admin1_name, country_name) INTO ret;
  RETURN ret;
END;
$$ LANGUAGE 'plpgsql' SECURITY DEFINER;
-- TODO: review all permissions stuff [I'd explicitly grant permissions to the public functions]

--------------------------------------------------------------------------------

---- geocode_namedplace_point(city_name text)
CREATE OR REPLACE FUNCTION cdb_geocoder_client._geocode_namedplace_point(user_id name, tx_id bigint, city_name text)
RETURNS Geometry AS $$
  CONNECT cdb_geocoder_client._server_conn_str();
  SELECT cdb_geocoder_server.geocode_namedplace_point(user_id, tx_id, city_name);
$$ LANGUAGE plproxy;

---- geocode_namedplace_point(city_name text, country_name text)
CREATE OR REPLACE FUNCTION cdb_geocoder_client._geocode_namedplace_point(user_id name, tx_id bigint, city_name text, country_name text)
RETURNS Geometry AS $$
  CONNECT cdb_geocoder_client._server_conn_str();
  SELECT cdb_geocoder_server.geocode_namedplace_point(user_id, tx_id, city_name, country_name);
$$ LANGUAGE plproxy;

---- geocode_namedplace_point(city_name text, admin1_name text, country_name text)
CREATE OR REPLACE FUNCTION cdb_geocoder_client._geocode_namedplace_point(user_id name, tx_id bigint, city_name text, admin1_name text, country_name text)
RETURNS Geometry AS $$
  CONNECT cdb_geocoder_client._server_conn_str();
  SELECT cdb_geocoder_server.geocode_namedplace_point(user_id, tx_id, city_name, admin1_name, country_name);
$$ LANGUAGE plproxy;