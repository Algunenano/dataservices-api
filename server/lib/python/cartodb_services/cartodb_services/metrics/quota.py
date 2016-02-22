from user import UserMetricsService
from datetime import date
import re


class QuotaService:
    """ Class to manage all the quota operation for
    the Geocoder SQL API Extension """

    def __init__(self, user_service_config, redis_connection):
        self._user_service_config = user_service_config
        # TODO First step to extract to a factory if needed in the future
        self._quota_checker = QuotaChecker(user_service_config,
                                           redis_connection)
        self._user_service = UserMetricsService(
            self._user_service_config, redis_connection)

    def check_user_quota(self):
        return self._quota_checker.check()

    # TODO
    # We are going to change this class to be the generic one and
    # create specific for routing and geocoding services but because
    # this implies change all the extension functions, we are going to
    # make the change in a minor release

    def increment_success_geocoder_use(self, amount=1):
        self._user_service.increment_service_use(
            self._user_service_config.service_type, "success_responses",
            amount=amount)

    def increment_empty_geocoder_use(self, amount=1):
        self._user_service.increment_service_use(
            self._user_service_config.service_type, "empty_responses",
            amount=amount)

    def increment_failed_geocoder_use(self, amount=1):
        self._user_service.increment_service_use(
            self._user_service_config.service_type, "fail_responses",
            amount=amount)

    def increment_total_geocoder_use(self, amount=1):
        self._user_service.increment_service_use(
            self._user_service_config.service_type, "total_requests",
            amount=amount)

    def increment_isolines_service_use(self, amount=1):
        self._user_service.increment_service_use(
            self._user_service_config.service_type, "isolines_generated",
            amount=amount)


class QuotaChecker:

    def __init__(self, user_service_config, redis_connection):
        self._user_service_config = user_service_config
        self._user_service = UserMetricsService(
            self._user_service_config, redis_connection)

    def check(self):
        """ Check if the current user quota surpasses the current quota """
        if re.match('geocoder_*',
                    self._user_service_config.service_type) is not None:
            return self.__check_geocoder_quota()
        elif re.match('here_isolines',
                      self._user_service_config.service_type) is not None:
            return self.__check_isolines_quota()
        else:
            return False

    def __check_geocoder_quota(self):
        # We don't have quota check for google geocoder
        if self._user_service_config.google_geocoder:
            return True

        user_quota = self._user_service_config.geocoding_quota
        today = date.today()
        service_type = self._user_service_config.service_type
        current_used = self._user_service.used_quota(service_type, today)
        soft_geocoding_limit = self._user_service_config.soft_geocoding_limit

        if soft_geocoding_limit or (user_quota > 0 and current_used <= user_quota):
            return True
        else:
            return False

    def __check_isolines_quota(self):
        user_quota = self._user_service_config.isolines_quota
        today = date.today()
        service_type = self._user_service_config.service_type
        current_used = self._user_service.used_quota(service_type, today)
        soft_isolines_limit = self._user_service_config.soft_isolines_limit

        if soft_isolines_limit or (user_quota > 0 and current_used <= user_quota):
            return True
        else:
            return False
