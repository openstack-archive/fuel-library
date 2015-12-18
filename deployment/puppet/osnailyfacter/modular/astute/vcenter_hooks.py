#!/usr/bin/env python
# -*- coding: utf-8 -*-

#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

from itertools import ifilter
from novaclient.client import Client
from optparse import OptionParser
import subprocess
import sys
import yaml


def get_data_from_hiera(key, resolution_type=':priority'):
    cmd = 'ruby -r hiera -r yaml -e \'hiera = Hiera.new(:config => \
          "/etc/puppet/hiera.yaml"); data = hiera.lookup "'+key+'", \
          [], {}, nil, '+resolution_type+';  puts YAML.dump data\''
    try:
        cmd_data = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    except subprocess.CalledProcessError as err:
        print("Error code", err.returncode, err.output)
        sys.exit(1)
    data = yaml.load(cmd_data.stdout.read())
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
        print("Zone {0} already present.".format(compute_zone))
    else:
        print("Zone {0} is missing, creating it.".format(compute_zone))
        nova_client.aggregates.create(compute_zone, compute_zone)


def check_host_in_zone(nova_client, compute):
    nova_aggregates = nova_client.aggregates.list()
    compute_zone = compute['availability_zone_name']
    compute_host = compute_zone + "-" + compute['service_name']
    present = filter(lambda aggr: compute_host in aggr.hosts, nova_aggregates)

    if present:
        print("Compute service {0} already in {1}  zone.".
              format(compute['service_name'], compute_zone))
    else:
        for aggregate in nova_aggregates:
            if aggregate.to_dict()['name'] == compute_zone:
                print("Compute service {0} not in {1} zone. Adding.".
                      format(compute['service_name'], compute_zone))
                nova_client.aggregates.add_host(aggregate, compute_host)


def main():
    credentials = get_data_from_hiera('access', ':hash')
    USERNAME = credentials['user']
    PASSWORD = credentials['password']
    PROJECT_ID = credentials['tenant']
    VERSION = 2
    IP = []
    IP.append(get_data_from_hiera('keystone_vip'))
    IP.append(get_data_from_hiera('senvice_endpoint'))
    IP.append(get_data_from_hiera('management_vip'))
    AUTH_URL = "http://" + ifilter(None, IP).next() + ":5000/v2.0/"

    parser = OptionParser()
    parser.add_option("--create_zones", action="store_true", help="Create \
                      needed availability zones and puts coresponding compute \
                      services in corresponding availability zones")
    (options, args) = parser.parse_args()

    nova = Client(VERSION, USERNAME, PASSWORD, PROJECT_ID, AUTH_URL,
                  endpoint_type='internalURL')
    vcenter_settings = get_data_from_hiera('vcenter', ':hash')

    if options.create_zones:
        for compute in vcenter_settings['computes']:
            print("---Start of Compute service {0} zone creation.---".
                  format(compute['service_name']))
            check_availability_zones(nova, compute)
            check_host_in_zone(nova, compute)
            print("----End of Compute service {0} ----".
                  format(compute['service_name']))


if __name__ == '__main__':
    main()
