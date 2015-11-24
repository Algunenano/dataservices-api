-- Mock the server functions
CREATE OR REPLACE FUNCTION cdb_geocoder_server.geocode_ip_point(user_id name, user_config JSON, geocoder_config JSON, ip_address text)
RETURNS Geometry AS $$
BEGIN
  RAISE NOTICE 'cdb_geocoder_server.geocode_ip_point invoked with params (%, %, %, %)', user_id, '{"is_organization": false, "entity_name": "test_user"}', '{"street_geocoder_provider": "nokia","nokia_monthly_quota": 100, "nokia_soft_geocoder_limit": false}', ip_address;
  RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';


-- Exercise the public and the proxied function
SELECT cdb_geocoder_client.geocode_ip_point('8.8.8.8');
