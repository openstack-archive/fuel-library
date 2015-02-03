#!/usr/bin/python
import os
import sys
import json
import subprocess
from novaclient.client import Client


VERSION = 2
USERNAME = os.environ.get('OS_USERNAME')
PASSWORD = os.environ.get('OS_PASSWORD')
PROJECT_ID = os.environ.get('OS_TENANT_NAME')
AUTH_URL = os.environ.get('OS_AUTH_URL')


def get_data_from_hiera(key):
    cmd_data = subprocess.Popen("hiera " + key, shell=True,
                                stdout=subprocess.PIPE).stdout.read(). \
        replace('=>', ':')
    try:
        data = json.loads(cmd_data)
    except:
        data = {key: cmd_data}
    return data


def check_availability_zones(nova_client, compute):
    nova_zones = nova_client.availability_zones.list()
    nova_aggregates = nova_client.aggregates.list()
    compute_zone = compute['availability_zone_name']
    a = next((az for az in nova_zones if az.to_dict()['zoneName'] ==
             compute_zone), None)
    b = next((az for az in nova_aggregates
             if az.to_dict()['availability_zone'] == compute_zone), None)
    if not (a or b):
        print "Zone " + compute_zone + " is missing, create it."
        nova_client.aggregates.create(compute_zone, compute_zone)
    else:
        print "Zone " + compute_zone + " already present."


def check_host_in_zone(nova_client, compute):
    nova_zones = nova_client.availability_zones.list()
    nova_aggregates = nova_client.aggregates.list()
    compute_zone = compute['availability_zone_name']
    compute_host = compute_zone + "-" + compute['service_name']

    for aggregate in nova_aggregates:
        if aggregate.to_dict()['name'] == compute_zone:
            host_aggregate = aggregate

    c = next((az for az in nova_zones if compute_host in
             az.to_dict()['hosts'] and az.to_dict()['zoneName'] ==
              compute_zone), None)
    if c is None:
        print "Compute service " + compute['service_name'] + " not in " + \
            compute_zone + " zone. " + "Adding."
        nova_client.aggregates.add_host(host_aggregate, compute_host)
    else:
        print "Compute service " + compute['service_name'] + " already in " + \
            compute_zone + " zone."

use_vcenter = get_data_from_hiera('use_vcenter')
if use_vcenter['use_vcenter'] is not True:
    sys.exit(0)

nova = Client(VERSION, USERNAME, PASSWORD, PROJECT_ID, AUTH_URL)
vcenter_settings = get_data_from_hiera('vcenter')

for compute in vcenter_settings['computes']:
    print "---Start of Compute service " + compute['service_name'] + \
        " zone creation.---"
    check_availability_zones(nova, compute)
    check_host_in_zone(nova, compute)
    print "----End of Compute service " + compute['service_name'] + "----\n"
