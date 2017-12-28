import unittest
from mock import Mock
from cartodb_services.mapbox import MapboxMatrixClient
from cartodb_services.mapbox.matrix_client import DEFAULT_PROFILE
from cartodb_services.mapbox import ServiceException
from cartodb_services.tools import Coordinate

VALID_TOKEN = 'pk.eyJ1IjoiYWNhcmxvbiIsImEiOiJjamJuZjQ1Zjc0Ymt4Mnh0YmFrMmhtYnY4In0.gt9cw0VeKc3rM2mV5pcEmg'
INVALID_TOKEN = 'invalid_token'
VALID_ORIGIN = Coordinate(-73.989, 40.733)
VALID_TARGET = Coordinate(-74, 40.733)
VALID_COORDINATES = [VALID_ORIGIN] + [VALID_TARGET]
NUM_COORDINATES_MAX = 25
INVALID_COORDINATES_EMPTY = []
INVALID_COORDINATES_MIN = [VALID_ORIGIN]
INVALID_COORDINATES_MAX = [VALID_ORIGIN] + \
                          [VALID_TARGET
                           for x in range(0, NUM_COORDINATES_MAX + 1)]
VALID_PROFILE = DEFAULT_PROFILE
INVALID_PROFILE = 'invalid_profile'


class MapboxMatrixTestCase(unittest.TestCase):
    def setUp(self):
        self.matrix_client = MapboxMatrixClient(token=VALID_TOKEN,
                                                logger=Mock())

    def test_invalid_profile(self):
        with self.assertRaises(ValueError):
            self.matrix_client.matrix(VALID_COORDINATES,
                                      INVALID_PROFILE)

    def test_invalid_coordinates_empty(self):
        with self.assertRaises(ValueError):
            self.matrix_client.matrix(INVALID_COORDINATES_EMPTY,
                                      VALID_PROFILE)

    def test_invalid_coordinates_max(self):
        with self.assertRaises(ValueError):
            self.matrix_client.matrix(INVALID_COORDINATES_MAX,
                                      VALID_PROFILE)

    def test_invalid_coordinates_min(self):
        with self.assertRaises(ValueError):
            self.matrix_client.matrix(INVALID_COORDINATES_MIN,
                                      VALID_PROFILE)

    def test_invalid_token(self):
        invalid_matrix = MapboxMatrixClient(token=INVALID_TOKEN, logger=Mock())
        with self.assertRaises(ServiceException):
            invalid_matrix.matrix(VALID_COORDINATES,
                                  VALID_PROFILE)

    def test_valid_request(self):
        distance_matrix = self.matrix_client.matrix(VALID_COORDINATES,
                                                    VALID_PROFILE)
        assert distance_matrix
