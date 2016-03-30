# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller.yaml
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl.yaml
# HIERA: neut_vxlan_dvr.murano.sahara-controller.yaml
# HIERA: neut_vxlan_dvr.murano.sahara-compute.yaml
# HIERA: neut_vxlan_dvr.murano.sahara-cinder.yaml
# HIERA: neut_vlan_l3ha.ceph.ceil-primary-mongo.yaml
# HIERA: neut_vlan_l3ha.ceph.ceil-primary-controller.yaml
# HIERA: neut_vlan_l3ha.ceph.ceil-controller.yaml
# HIERA: neut_vlan_l3ha.ceph.ceil-compute.yaml
# HIERA: neut_vlan_l3ha.ceph.ceil-ceph-osd.yaml
# HIERA: neut_vlan.ironic.controller.yaml
# HIERA: neut_vlan.ironic.conductor.yaml
# HIERA: neut_vlan.compute.ssl.yaml
# HIERA: neut_vlan.compute.ssl.overridden.yaml
# HIERA: neut_vlan.compute.nossl.yaml
# HIERA: neut_vlan.cinder-block-device.compute.yaml
# HIERA: neut_vlan.ceph.controller-ephemeral-ceph.yaml
# HIERA: neut_vlan.ceph.compute-ephemeral-ceph.yaml
# HIERA: neut_vlan.ceph.ceil-primary-controller.overridden_ssl.yaml
# HIERA: neut_vlan.ceph.ceil-compute.overridden_ssl.yaml
# HIERA: neut_gre.generate_vms.yaml
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

