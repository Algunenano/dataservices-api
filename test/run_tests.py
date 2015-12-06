import getopt
import sys
import requests
import time
import json
import subprocess
import os


def main():
    opts, args = getopt.getopt(sys.argv[1:], "h", ["help", "host="])

    if len(args) < 2:
        usage()
        sys.exit()

    host = "cartodb.com"
    username = args[0]
    api_key = args[1]
    table_name = "geocoder_api_test_dataset_".format(int(time.time()))
    for o, a in opts:
        if o in ("-h", "--help"):
            usage()
            sys.exit()
        elif o in ("--host"):
            host = opts[0][1]
        else:
            assert False, "unhandled option"

    try:
        table_name = import_test_dataset(username, api_key, host)
        set_environment_variables(username, api_key, table_name, host)
        execute_tests()
    finally:
        clean_environment_variables()
        clean_test_dataset(username, api_key, table_name, host)


def usage():
    print """Usage: run_tests.py [options] username api_key
        Options:
        -h: Show this help
        --host: take that host as base (by default is cartodb.com)"""


def import_test_dataset(username, api_key, host):
    url = "https://{0}.{1}/api/v1/imports/"\
        "?type_guessing=false&api_key={2}".format(
        username, host, api_key)
    dataset = {'file': open('fixtures/geocoder_api_test_dataset.csv', 'rb')}
    response = requests.post(url, files=dataset)
    response_json = json.loads(response.text)
    if not response_json['success']:
        print "Error importing the test dataset: {0}".format(response.text)
        sys.exit(1)
    while(True):
        table_name = get_imported_table_name(
            username,
            host,
            api_key,
            response_json['item_queue_id']
        )
        if table_name:
            return table_name
        else:
            time.sleep(5)


def get_imported_table_name(username, host, api_key, import_id):
    import_data_url = "https://{0}.{1}/api/v1/imports/{2}?api_key={3}".format(
        username, host, import_id, api_key
    )
    import_data_response = requests.get(import_data_url)
    if import_data_response.status_code != 200:
        print "Error getting the table name from the import data: {0}".format(
            import_data_response.text
        )
        sys.exit(1)
    import_data_json = json.loads(import_data_response.text)

    return import_data_json['table_name']


def execute_tests():
    print "Start testing..."
    process = subprocess.Popen(["nosetests", "--where=integration/"])
    process.wait()
    print "Testing finished!"


def set_environment_variables(username, api_key, table_name, host):
    os.environ["GEOCODER_API_TEST_USERNAME"] = username
    os.environ["GEOCODER_API_TEST_API_KEY"] = api_key
    os.environ["GEOCODER_API_TEST_TABLE_NAME"] = table_name
    os.environ["GEOCODER_API_TEST_HOST"] = host


def clean_environment_variables():
    print "Cleaning test dataset environment variables..."
    del os.environ["GEOCODER_API_TEST_USERNAME"]
    del os.environ["GEOCODER_API_TEST_API_KEY"]
    del os.environ["GEOCODER_API_TEST_TABLE_NAME"]
    del os.environ["GEOCODER_API_TEST_HOST"]


def clean_test_dataset(username, api_key, table_name, host):
    print "Cleaning test dataset {0}...".format(table_name)
    url = "https://{0}.{1}/api/v2/sql?q=drop table {2}&api_key={3}".format(
        username, host, table_name, api_key
    )
    response = requests.get(url)
    if response.status_code != 200:
        print "Error cleaning the test dataset: {0}".format(response.text)
        sys.exit(1)

if __name__ == "__main__":
    main()
