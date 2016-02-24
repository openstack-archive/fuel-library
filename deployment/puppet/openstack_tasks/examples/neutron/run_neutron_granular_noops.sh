#!/bin/sh

for yaml in \
  novanet-compute.yaml \
  neut_vlan.ceph.ceil-primary-controller.yaml \
  neut_vxlan.sahara-primary-controller.yaml \
  novanet-primary-controller.yaml \
  ; do
  for spec in \
  openstack-network/compute-nova_spec.rb \
  openstack-network/common-config_spec.rb \
  openstack-network/server_spec.rb \
  openstack-network/server-nova_spec.rb \
  openstack-network/agents/dhcp_spec.rb \
  openstack-network/agents/l3_spec.rb \
  openstack-network/agents/metadata_spec.rb \
  openstack-network/agents/l2_spec.rb \
  openstack-network/networks_spec.rb \
  openstack-network/routers_spec.rb \
  ; do
    echo ./utils/jenkins/fuel_noop_tests.rb -y "${yaml}" -s "${spec}" -C -D ${@}
  done
done
