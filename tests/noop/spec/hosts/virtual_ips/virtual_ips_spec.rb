# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.ironic.controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'virtual_ips/virtual_ips.pp'

describe manifest do
  shared_examples 'catalog' do
    # TODO: test vip parameters too

    Noop.hiera_structure('network_metadata/vips', {}).each do |name, params|
      next unless params['network_role']
      next unless params['node_roles']
      if params['namespace']
        it "should have '#{name}' VIP" do
          expect(subject).to contain_cluster__virtual_ip(name)
        end
      end
    end
  end

  test_ubuntu_and_centos manifest
end
