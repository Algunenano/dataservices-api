import os
import requests
import json

import time

class ImportHelper:

    @classmethod
    def import_test_dataset(cls, username, api_key, host):
        requests.packages.urllib3.disable_warnings()
        url = "https://{0}.{1}/api/v1/imports/"\
            "?type_guessing=false&api_key={2}".format(
            username, host, api_key)
        dataset = {
            'file': open('fixtures/geocoder_api_test_dataset.csv', 'rb')}
        response = requests.post(url, files=dataset)
        response_json = json.loads(response.text)
        if not response_json['success']:
            print "Error importing the test dataset: {0}".format(response.text)
            sys.exit(1)
        while(True):
            table_name = ImportHelper.get_imported_table_name(
                username,
                host,
                api_key,
                response_json['item_queue_id']
            )
            if table_name:
                return table_name
            else:
                time.sleep(5)

    @classmethod
    def get_imported_table_name(cls, username, host, api_key, import_id):
        requests.packages.urllib3.disable_warnings()
        import_url = "https://{0}.{1}/api/v1/imports/{2}?api_key={3}".format(
            username, host, import_id, api_key)
        import_data_response = requests.get(import_url)
        if import_data_response.status_code != 200:
            print "Error getting the table name from " \
                "the import data: {0}".format(
                import_data_response.text)
            sys.exit(1)
        import_data_json = json.loads(import_data_response.text)

        return import_data_json['table_name']

    @classmethod
    def clean_test_dataset(cls, username, api_key, table_name, host):
        requests.packages.urllib3.disable_warnings()
        url = "https://{0}.{1}/api/v2/sql?q=drop table {2}&api_key={3}".format(
            username, host, table_name, api_key
        )
        response = requests.get(url)
        if response.status_code != 200:
            print "Error cleaning the test dataset: {0}".format(response.text)
            sys.exit(1)
