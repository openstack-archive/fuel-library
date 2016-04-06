# ROLE: virt
# ROLE: primary-mongo
# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: primary-controller
# ROLE: mongo
# ROLE: mongo
# ROLE: ironic
# ROLE: ironic
# ROLE: controller
# ROLE: controller
# ROLE: compute-vmware
# ROLE: compute-vmware
# ROLE: compute
# ROLE: compute
# ROLE: cinder-vmware
# ROLE: cinder-vmware
# ROLE: cinder-block-device
# ROLE: cinder-block-device
# ROLE: cinder
# ROLE: cinder
# ROLE: ceph-osd
# ROLE: ceph-osd
# ROLE: base-os
# R_N: neut_gre.generate_vms ubuntu
require 'spec_helper'
require 'shared-examples'
manifest = 'hosts/hosts.pp'

describe manifest do
  shared_examples 'catalog' do

    network_metadata = Noop.hiera_structure('network_metadata/nodes')
    messaging_fqdn_prefix = Noop.hiera('node_name_prefix_for_messaging', 'messaging-')

    it 'should create basic host entries' do
      network_metadata.each do |node, params|
        should contain_host(params['fqdn']).with({
          :ip => params['network_roles']['mgmt/vip'],
          :host_aliases => ["#{node}"],
          :target => '/etc/hosts'
        })
      end
    end

    it 'should create host entries for messaging network with correct prefix' do
      network_metadata.each do |node, params|
        should contain_host("#{messaging_fqdn_prefix}#{params['fqdn']}").with({
          :ip => params['network_roles']['mgmt/messaging'],
          :host_aliases => ["#{messaging_fqdn_prefix}#{node}"],
          :target => '/etc/hosts'
        })
      end

    end
  end
  test_ubuntu_and_centos manifest
end

