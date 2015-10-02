#!/bin/sh

for yaml in neut_vlan.ceph.ceil-primary-controller.yaml neut_vxlan.murano.sahara-primary-controller.yaml novanet-primary-controller.yaml; do
  for spec in \
  openstack-network/common-config_spec.rb \
  openstack-network/server_spec.rb \
  openstack-network/nova_spec.rb \
  openstack-network/agents/dhcp_spec.rb \
  openstack-network/agents/l2_spec.rb \
  openstack-network/agents/l3_spec.rb \
  openstack-network/agents/metadata_spec.rb \
  openstack-network/networks_spec.rb \
  openstack-network/routers_spec.rb \
  ; do
    log="`basename ${yaml}`-`basename ${spec}`.log"
    echo ./utils/jenkins/fuel_noop_tests.rb -y "${yaml}" -s "${spec}" -C -D ${@}
    if [ -z "${DEBUG}" ]; then
      ./utils/jenkins/fuel_noop_tests.rb -y "${yaml}" -s "${spec}" -C -D ${@}
    fi
  done
done
