#!/bin/bash
# This example script shows how to create a simple subnet for Neutron.

source /root/openrc
neutron net-create mynet
neutron subnet-create --name mynet-subnet mynet 10.0.0.0/24
neutron router-create myrouter
neutron router-interface-add myrouter mynet-subnet
