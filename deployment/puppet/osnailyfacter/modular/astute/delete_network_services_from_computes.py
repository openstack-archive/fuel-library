#!/usr/bin/python
import os
import sys
import json
import subprocess
from novaclient.client import Client


def get_data_from_hiera(key):
    cmd_data = subprocess.Popen("hiera " + key, shell=True,
                                stdout=subprocess.PIPE).stdout.read(). \
        replace('=>', ':').replace('nil', '"null"')
    try:
        data = json.loads(cmd_data)
    except:
        data = {key: cmd_data.strip()}
    return data


def delete_nova_service(client, service_id):
    client.services.delete(service_id)


use_vcenter = get_data_from_hiera('use_vcenter')
if use_vcenter is not True:
    sys.exit(0)

credentials = get_data_from_hiera('access')
USERNAME = credentials['user']
PASSWORD = credentials['password']
PROJECT_ID = credentials['tenant']
VERSION = 2
IP = get_data_from_hiera('management_vip')['management_vip']
AUTH_URL = "http://" + IP + ":5000/v2.0/"

nodes = get_data_from_hiera('nodes')
nova = Client(VERSION, USERNAME, PASSWORD, PROJECT_ID, AUTH_URL)

for node in nodes:
    if node['role'] == 'compute':
        network_services = nova.services.list(node['name'], 'nova-network')
        for network_service in network_services:
            print "Found unusable nova-network on " + node['name'] + \
                  " compute node, deleting it."
            delete_nova_service(nova, network_service.to_dict()['id'])
