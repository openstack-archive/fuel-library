#!/usr/bin/python
import sys
import json
import subprocess
from optparse import OptionParser
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


def check_availability_zones(nova_client, compute):
    nova_zones = nova_client.availability_zones.list()
    nova_aggregates = nova_client.aggregates.list()
    nova_zones_and_aggregates = nova_aggregates + nova_zones
    compute_zone = compute['availability_zone_name']
    present = filter(lambda item: item.to_dict().get('zoneName') ==
                     compute_zone or item.to_dict().get('availability_zone') ==
                     compute_zone, nova_zones_and_aggregates)
    if present:
        print "Zone {0} already present.".format(compute_zone)
    else:
        print "Zone {0} is missing, creating it.".format(compute_zone)
        nova_client.aggregates.create(compute_zone, compute_zone)


def check_host_in_zone(nova_client, compute):
    nova_zones = nova_client.availability_zones.list()
    nova_aggregates = nova_client.aggregates.list()
    compute_zone = compute['availability_zone_name']
    compute_host = compute_zone + "-" + compute['service_name']

    for aggregate in nova_aggregates:
        if aggregate.to_dict()['name'] == compute_zone:
            host_aggregate = aggregate

    present = filter(lambda item: compute_host in item.to_dict()['hosts'] and
                     item.to_dict()['zoneName'] == compute_zone, nova_zones)

    if present:
        print "Compute service {0} already in {1}  zone.". \
            format(compute['service_name'], compute_zone)
    else:
        print "Compute service {0} not in {1} zone. Adding.". \
            format(compute['service_name'], compute_zone)
        nova_client.aggregates.add_host(host_aggregate, compute_host)


def delete_nova_service(client, service_id):
            client.services.delete(service_id)


def main():
    credentials = get_data_from_hiera('access')
    USERNAME = credentials['user']
    PASSWORD = credentials['password']
    PROJECT_ID = credentials['tenant']
    VERSION = 2
    IP = get_data_from_hiera('management_vip')['management_vip']
    AUTH_URL = "http://" + IP + ":5000/v2.0/"

    parser = OptionParser()
    parser.add_option("--create_zones", action="store_false", help="Create \
                      needed availability zones and puts coresponding compute \
                      services in corresponding availability zones")
    parser.add_option("--delete_network_services", action="store_false",
                      help="Delete unusable nova-network services from \
                      computes")
    (options, args) = parser.parse_args()

    nova = Client(VERSION, USERNAME, PASSWORD, PROJECT_ID, AUTH_URL)
    vcenter_settings = get_data_from_hiera('vcenter')

    if options.create_zones is True:
        for compute in vcenter_settings['computes']:
            print "---Start of Compute service {0} zone creation.---". \
                format(compute['service_name'])
            check_availability_zones(nova, compute)
            check_host_in_zone(nova, compute)
            print "----End of Compute service {0} ----". \
                format(compute['service_name'])
    elif options.delete_network_services is True:
        for node in nodes:
            if node['role'] == 'compute':
                network_services = nova.services.list(node['name'],
                                                      'nova-network')
                for network_service in network_services:
                    print "Found unusable nova-network on {0} compute \
                           node, deleting it.".format(node['name'])
                    delete_nova_service(nova, network_service.to_dict()['id'])


if __name__ == '__main__':
    main()
