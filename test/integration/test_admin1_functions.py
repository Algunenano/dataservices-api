from unittest import TestCase
from nose.tools import assert_raises
from nose.tools import assert_not_equal, assert_equal
from ..helpers.integration_test_helper import IntegrationTestHelper


class TestAdmin1Functions(TestCase):

    def setUp(self):
        self.env_variables = IntegrationTestHelper.get_environment_variables()
        self.sql_api_url = "https://{0}.{1}/api/v2/sql".format(
            self.env_variables['username'],
            self.env_variables['host'],
            self.env_variables['api_key']
        )

    def test_if_select_with_admin1_without_country_is_ok(self):
        query = "SELECT cdb_geocode_admin1_polygon(province) as geometry " \
            "FROM {0} LIMIT 1&api_key={1}".format(
            self.env_variables['table_name'],
            self.env_variables['api_key'])
        geometry = IntegrationTestHelper.execute_query(self.sql_api_url, query)
        assert_not_equal(geometry['geometry'], None)

    def test_if_select_with_admin1_with_country_is_ok(self):
        query = "SELECT cdb_geocode_admin1_polygon(province,country)" \
            "as geometry FROM {0} LIMIT 1&api_key={1}".format(
            self.env_variables['table_name'],
            self.env_variables['api_key'])
        geometry = IntegrationTestHelper.execute_query(self.sql_api_url, query)
        assert_not_equal(geometry['geometry'], None)

    def test_if_select_with_admin1_without_api_key_raise_error(self):
        query = "SELECT cdb_geocode_admin1_polygon(province) as geometry " \
            "FROM {0} LIMIT 1".format(
            self.env_variables['table_name'])
        try:
            IntegrationTestHelper.execute_query(self.sql_api_url, query)
        except Exception as e:
            assert_equal(e.message[0], "The api_key must be provided")
