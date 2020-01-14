import unittest
from mock import Mock
from cartodb_services.geocodio import GeocodioGeocoder
from cartodb_services.geocodio import GeocodioBulkGeocoder
from cartodb_services.tools.exceptions import ServiceException
from credentials import geocodio_api_key

INVALID_TOKEN = 'invalid_token'

VALID_ADDRESS_1 = 'Lexington Ave, New York, US'
VALID_ADDRESS_2 = 'E 14th St; New York; US'

WELL_KNOWN_LONGITUDE_1 = -74.365
WELL_KNOWN_LATITUDE_1 = 42.240
WELL_KNOWN_LONGITUDE_2 = -73.983
WELL_KNOWN_LATITUDE_2 = 40.731

VALID_SEARCH_TEXT='Lexington Ave'
VALID_CITY='New York'
VALID_STATE_PROVINCE='New York'
VALID_COUNTRY='USA'

WELL_KNOWN_LONGITUDE_COMPONENTS = -76.710
WELL_KNOWN_LATITUDE_COMPONENTS = 39.964

SEARCH_ID_1 = 1
SEARCH_ID_2 = 2


class GeocodioGeocoderTestCase(unittest.TestCase):
    def setUp(self):
        self.geocoder = GeocodioGeocoder(token=geocodio_api_key(), logger=Mock())
        self.bulk_geocoder = GeocodioBulkGeocoder(token=geocodio_api_key(), logger=Mock())

    ### NON BULK

    def test_invalid_token(self):
        invalid_geocoder = GeocodioGeocoder(token=INVALID_TOKEN, logger=Mock())
        with self.assertRaises(ServiceException):
            invalid_geocoder.geocode(VALID_ADDRESS_1)

    def test_valid_request(self):
        place = self.geocoder.geocode(VALID_ADDRESS_1)

        self.assertEqual('%.3f' % place[0], '%.3f' % WELL_KNOWN_LONGITUDE_1)
        self.assertEqual('%.3f' % place[1], '%.3f' % WELL_KNOWN_LATITUDE_1)

    def test_valid_request_components(self):
        place = self.geocoder.geocode(searchtext=VALID_SEARCH_TEXT,
                                      city=VALID_CITY,
                                      state_province=VALID_STATE_PROVINCE,
                                      country=VALID_COUNTRY)

        self.assertEqual('%.3f' % place[0], '%.3f' % WELL_KNOWN_LONGITUDE_COMPONENTS)
        self.assertEqual('%.3f' % place[1], '%.3f' % WELL_KNOWN_LATITUDE_COMPONENTS)

    def test_valid_request_namedplace(self):
        place = self.geocoder.geocode(searchtext='New York')

        assert place

    def test_valid_request_namedplace2(self):
        place = self.geocoder.geocode(searchtext='New York', country='us')

        assert place

    def test_odd_characters(self):
        place = self.geocoder.geocode(searchtext='New York; &quot;USA&quot;')

        assert place

    def test_empty_request(self):
        place = self.geocoder.geocode(searchtext='', country=None, city=None, state_province=None)

        assert place == []

    def test_empty_search_text_request(self):
        place = self.geocoder.geocode(searchtext='     ', country='us', city=None, state_province="")

        assert place == []

    def test_unknown_place_request(self):
        place = self.geocoder.geocode(searchtext='[unknown]', country='ch', state_province=None, city=None)

        assert place == []

    ### BULK ONE

    def test_invalid_token_bulk_one(self):
        invalid_geocoder = GeocodioBulkGeocoder(token=INVALID_TOKEN, logger=Mock())
        with self.assertRaises(ServiceException):
            invalid_geocoder._batch_geocode([(SEARCH_ID_1, VALID_ADDRESS_1, None, None, None)])

    def test_valid_request_bulk_one(self):
        place = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, VALID_ADDRESS_1, None, None, None)])

        self.assertEqual(place[0][0], SEARCH_ID_1)
        self.assertEqual('%.3f' % place[0][1], '%.3f' % WELL_KNOWN_LONGITUDE_1)
        self.assertEqual('%.3f' % place[0][2], '%.3f' % WELL_KNOWN_LATITUDE_1)

    def test_valid_request_components_bulk_one(self):
        place = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, VALID_SEARCH_TEXT, VALID_CITY, VALID_STATE_PROVINCE, VALID_COUNTRY)])

        self.assertEqual(place[0][0], SEARCH_ID_1)
        self.assertEqual('%.3f' % place[0][1], '%.3f' % WELL_KNOWN_LONGITUDE_COMPONENTS)
        self.assertEqual('%.3f' % place[0][2], '%.3f' % WELL_KNOWN_LATITUDE_COMPONENTS)

    def test_valid_request_namedplace_bulk_one(self):
        place = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, 'New York', None, None, None)])

        assert place

    def test_valid_request_namedplace2_bulk_one(self):
        place = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, 'New York', 'us', None, None)])

        assert place

    def test_odd_characters_bulk_one(self):
        place = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, 'New York; &quot;USA&quot;', None, None, None)])

        assert place

    def test_empty_request_bulk_one(self):
        place = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, '', None, None, None)])

        assert place == [(SEARCH_ID_1, None, None)]

    def test_empty_search_text_request_bulk_one(self):
        place = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, '     ', 'us', None, "")])

        assert place == [(SEARCH_ID_1, None, None)]

    def test_unknown_place_request_bulk_one(self):
        place = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, '[unknown]', 'ch', None, None)])

        assert place == [(SEARCH_ID_1, None, None)]

    ### BULK MANY

    def test_invalid_token_bulk_many(self):
        invalid_geocoder = GeocodioBulkGeocoder(token=INVALID_TOKEN, logger=Mock())
        with self.assertRaises(ServiceException):
            invalid_geocoder._batch_geocode([(SEARCH_ID_1, VALID_ADDRESS_1, None, None, None),
                                             (SEARCH_ID_2, VALID_ADDRESS_2, None, None, None)])

    def test_valid_request_bulk_many(self):
        places = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, VALID_ADDRESS_1, None, None, None),
                                                   (SEARCH_ID_2, VALID_ADDRESS_2, None, None, None)])

        self.assertEqual(places[0][0], SEARCH_ID_1)
        self.assertEqual('%.3f' % places[0][1][0], '%.3f' % WELL_KNOWN_LONGITUDE_1)
        self.assertEqual('%.3f' % places[0][1][1], '%.3f' % WELL_KNOWN_LATITUDE_1)

        self.assertEqual(places[1][0], SEARCH_ID_2)
        self.assertEqual('%.3f' % places[1][1][0], '%.3f' % WELL_KNOWN_LONGITUDE_2)
        self.assertEqual('%.3f' % places[1][1][1], '%.3f' % WELL_KNOWN_LATITUDE_2)

    def test_valid_request_components_bulk_many(self):
        places = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, VALID_SEARCH_TEXT, VALID_CITY, VALID_STATE_PROVINCE, VALID_COUNTRY),
                                                    (SEARCH_ID_2, VALID_SEARCH_TEXT, VALID_CITY, VALID_STATE_PROVINCE, VALID_COUNTRY)])

        self.assertEqual(places[0][0], SEARCH_ID_1)
        self.assertEqual(places[1][0], SEARCH_ID_2)

    def test_valid_request_namedplace_bulk_many(self):
        places = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, 'New York', None, None, None),
                                                    (SEARCH_ID_2, 'Los Angeles', None, None, None)])

        assert places

        self.assertEqual(places[0][0], SEARCH_ID_1)
        self.assertEqual(places[1][0], SEARCH_ID_2)

    def test_valid_request_namedplace2_bulk_many(self):
        places = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, 'New York', 'us', None, None),
                                                    (SEARCH_ID_2, 'Los Angeles', None, None, None)])

        assert places

        self.assertEqual(places[0][0], SEARCH_ID_1)
        self.assertEqual(places[1][0], SEARCH_ID_2)

    def test_odd_characters_bulk_many(self):
        places = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, 'New York; &quot;USA&quot;', None, None, None),
                                                    (SEARCH_ID_2, 'Los Angeles', None, None, None)])

        assert places

        self.assertEqual(places[0][0], SEARCH_ID_1)
        self.assertEqual(places[1][0], SEARCH_ID_2)

    def test_empty_request_bulk_many(self):
        places = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, '', None, None, None),
                                                    (SEARCH_ID_2, '', None, None, None)])

        assert places == [(SEARCH_ID_1, [], {}), (SEARCH_ID_2, [], {})]

    def test_empty_search_text_request_bulk_many(self):
        places = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, '     ', 'us', None, ""),
                                                    (SEARCH_ID_2, '     ', 'us', None, "")])

        assert places == [(SEARCH_ID_1, [], {}), (SEARCH_ID_2, [], {})]

    def test_unknown_place_request_bulk_many(self):
        places = self.bulk_geocoder._batch_geocode([(SEARCH_ID_1, '[unknown]', 'ch', None, None),
                                                    (SEARCH_ID_2, '[unknown]', 'ch', None, None)])

        assert places == [(SEARCH_ID_1, [], {}), (SEARCH_ID_2, [], {})]
