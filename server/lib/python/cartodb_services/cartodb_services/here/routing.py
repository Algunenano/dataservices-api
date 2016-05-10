import requests
import json

from exceptions import WrongParams


class HereMapsRoutingIsoline:
    'A Here Maps Routing wrapper for python'

    PRODUCTION_ROUTING_BASE_URL = 'https://isoline.route.api.here.com'
    STAGING_ROUTING_BASE_URL = 'https://isoline.route.cit.api.here.com'
    ISOLINE_PATH = '/routing/7.2/calculateisoline.json'

    ACCEPTED_MODES = {
        "walk": "pedestrian",
        "car": "car"
    }

    OPTIONAL_PARAMS = [
        'departure',
        'arrival',
        'singlecomponent',
        'resolution',
        'maxpoints',
        'quality'
    ]

    def __init__(self, app_id, app_code, base_url=PRODUCTION_ROUTING_BASE_URL):
        self._app_id = app_id
        self._app_code = app_code
        self._url = "{0}{1}".format(base_url, self.ISOLINE_PATH)

    def calculate_isodistance(self, source, mode, data_range, options=[]):
        return self.__calculate_isolines(source, mode, data_range, 'distance',
                                         options)

    def calculate_isochrone(self, source, mode, data_range, options=[]):
        return self.__calculate_isolines(source, mode, data_range, 'time',
                                         options)

    def __calculate_isolines(self, source, mode, data_range, range_type,
                             options=[]):
        parsed_options = self.__parse_options(options)
        source_param = self.__parse_source_param(source, parsed_options)
        mode_param = self.__parse_mode_param(mode, parsed_options)
        request_params = self.__parse_request_parameters(source_param,
                                                         mode_param,
                                                         data_range,
                                                         range_type,
                                                         parsed_options)
        response = requests.get(self._url, params=request_params)
        if response.status_code == requests.codes.ok:
            return self.__parse_isolines_response(response.text)
        elif response.status_code == requests.codes.bad_request:
            return []
        else:
            response.raise_for_status()

    def __parse_options(self, options):
        return dict(option.split('=') for option in options)

    def __parse_request_parameters(self, source, mode, data_range, range_type,
                                   options):
        filtered_options = {k: v for k, v in options.iteritems()
                            if k.lower() in self.OPTIONAL_PARAMS}
        filtered_options.update(source)
        filtered_options.update(mode)
        filtered_options.update({'range': ",".join(map(str, data_range))})
        filtered_options.update({'rangetype': range_type})
        filtered_options.update({'app_id': self._app_id})
        filtered_options.update({'app_code': self._app_code})

        return filtered_options

    def __parse_isolines_response(self, response):
        parsed_response = json.loads(response)
        isolines_response = parsed_response['response']['isoline']
        isolines = []
        for isoline in isolines_response:
            isolines.append({'range': isoline['range'],
                             'geom': isoline['component'][0]['shape']})

        return isolines

    def __parse_source_param(self, source, options):
        key = 'start'
        if 'is_destination' in options and options['is_destination']:
            key = 'destination'

        return {key: source}

    def __parse_mode_param(self, mode, options):
        if mode in self.ACCEPTED_MODES:
            mode_source = self.ACCEPTED_MODES[mode]
        else:
            raise WrongParams("{0} is not an accepted mode type".format(mode))

        if 'mode_type' in options:
            mode_type = options['mode_type']
        else:
            mode_type = 'shortest'

        if 'mode_traffic' in options:
            mode_traffic = "traffic:{0}".format(options['mode_traffic'])
        else:
            mode_traffic = None

        if 'mode_feature' in options and 'mode_feature_weight' in options:
            mode_feature = "{0}:{1}".format(options['mode_feature'],
                                     options['mode_feature_weight'])
        else:
            mode_feature = None

        mode_param = "{0};{1}".format(mode_type, mode_source)
        if mode_traffic:
            mode_param = "{0};{1}".format(mode_param, mode_traffic)

        if mode_feature:
            mode_param = "{0};{1}".format(mode_param, mode_feature)

        return {'mode': mode_param}
