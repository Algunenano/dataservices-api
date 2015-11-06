-- Check if a given host is up by performing a ping -c 1 call.
CREATE OR REPLACE FUNCTION cdb_geocoder_server._check_host(hostname TEXT)
  RETURNS BOOLEAN
AS $$
  import os

  response = os.system("ping -c 1 " + hostname)

  return False if response else True
$$ LANGUAGE plpythonu VOLATILE;

-- Returns current pwd
CREATE OR REPLACE FUNCTION cdb_geocoder_server._pwd()
  RETURNS TEXT
AS $$
  import os

  return os.getcwd()
$$ LANGUAGE plpythonu VOLATILE;
