import json
import urllib

from heremapsexceptions import BadGeocodingParams, EmptyGeocoderResponse, NoGeocodingParams

class Geocoder:
    'A Here Maps Geocoder wrapper for python'

    URL_GEOCODE_JSON = 'http://geocoder.cit.api.here.com/6.2/geocode.json'
    MAX_RESULTS = 1

    ADDRESS_PARAMS = [
        'city',
        'country',
        'county',
        'district',
        'housenumber',
        'postalcode',
        'searchtext',
        'state',
        'street'
        ]

    ADMITTED_PARAMS = [
        'additionaldata',
        'app_id',
        'app_code',
        'bbox',
        'countryfocus',
        'gen',
        'jsonattributes',
        'jsoncallback',
        'language',
        'locationattributes',
        'locationid',
        'mapview',
        'maxresults',
        'pageinformation',
        'politicalview',
        'prox',
        'strictlanguagemode'
        ] + ADDRESS_PARAMS

    app_id = ''
    app_code = ''

    def __init__(self, app_id, app_code):
        self.app_id = app_id
        self.app_code = app_code

    def geocode(self, params):
        if not set(params.keys()).issubset(set(self.ADDRESS_PARAMS)):
            raise BadGeocodingParams(params)

        request_params = {
            'app_id' : self.app_id,
            'app_code' : self.app_code,
            'maxresults' : self.MAX_RESULTS,
            'gen' : '9'
            }
        request_params.update(params)

        encoded_request_params = urllib.urlencode(request_params)

        response = json.load(
            urllib.urlopen(self.URL_GEOCODE_JSON
                + '?'
                + encoded_request_params))

        return response

    def geocodeAddress(self, **kwargs):
        params = {}
        for key, value in kwargs.iteritems():
            if value: params[key] = value

        if not params: raise NoGeocodingParams()

        return self.geocode(params)

    def extractLngLatFromResponse(self, response):
        view = response['Response']['View']

        if len(view) is 0: raise EmptyGeocoderResponse()

        location = view[0]['Result'][0]['Location']

        longitude = location['DisplayPosition']['Longitude']
        latitude = location['DisplayPosition']['Latitude']

        return [longitude, latitude]
