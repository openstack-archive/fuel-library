#!/usr/bin/python
import os
import sys
import json
from novaclient.client import Client


def get_data_from_hiera(key):
    data = os.popen("hiera " + key).read().replace('=>', ':')
    try:
        data = json.loads(data)
    except:
        pass
    return data


def check_availability_zones(nova_client, compute):
    nova_zones = nova_client.availability_zones.list()
    nova_aggregates = nova_client.aggregates.list()
    compute_zone = compute['availability_zone_name']
    a = next((az for az in nova_zones if az.to_dict()['zoneName'] ==
             compute_zone), None)
    b = next((az for az in nova_aggregates
             if az.to_dict()['availability_zone'] == compute_zone), None)
    if a is None and b is None:
        print "Zone " + compute_zone + " is missing, create it."
        nova_client.aggregates.create(compute_zone, compute_zone)
    else:
        print "Zone " + compute_zone + " already present."


def check_host_in_zone(nova_client, compute):
    nova_zones = nova_client.availability_zones.list()
    compute_host = compute['availability_zone_name'] + "-" + \
        compute['service_name']
    c = next((az for az in nova_zones if compute_host in
             az.to_dict()['hosts']), None)
    if c is None:
        print "Compute service " + compute['service_name'] + " not in " + \
            compute['availability_zone_name'] + " zone. " + "Adding."
        nova_client.aggregates.add_host(compute['availability_zone_name'],
                                        compute_host)
    else:
        print "Compute service " + compute['service_name'] + " already in " + \
            compute['availability_zone_name'] + " zone."

use_vcenter = get_data_from_hiera('use_vcenter')
if use_vcenter is not True:
    sys.exit(0)

VERSION = 2
USERNAME = os.environ.get('OS_USERNAME')
PASSWORD = os.environ.get('OS_PASSWORD')
PROJECT_ID = os.environ.get('OS_TENANT_NAME')
AUTH_URL = os.environ.get('OS_AUTH_URL')

nova = Client(VERSION, USERNAME, PASSWORD, PROJECT_ID, AUTH_URL)
vcenter_settings = get_data_from_hiera('vcenter')

for compute in vcenter_settings['computes']:
    print "---Start of Compute service " + compute['service_name'] + \
        " zone creation.---"
    check_availability_zones(nova, compute)
    check_host_in_zone(nova, compute)
    print "----End of Compute service " + compute['service_name'] + "----\n"
