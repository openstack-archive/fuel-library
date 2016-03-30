# HIERA: neut_vlan.ceph.ceil-primary-controller.overridden_ssl
# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# HIERA: neut_vlan.ironic.controller
# HIERA: neut_vlan_l3ha.ceph.ceil-controller
# HIERA: neut_vlan_l3ha.ceph.ceil-primary-controller
# HIERA: neut_vxlan_dvr.murano.sahara-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl

require 'spec_helper'
require 'shared-examples'
manifest = 'astute/dump_rabbitmq_definitions.pp'

describe manifest do
  shared_examples 'catalog' do
    rabbit_hash = Noop.hiera_structure 'rabbit'
    management_bind_ip_address = Noop.hiera 'management_bind_ip_address', '127.0.0.1'
    management_port = Noop.hiera 'management_port', '15672'
    original_definitions_dump_file = '/etc/rabbitmq/definitions.full'
    rabbit_api_endpoint = "http://#{management_bind_ip_address}:#{management_port}/api/definitions"

    it "should contain rabbitmq dump definitions exec" do

      should contain_dump_rabbitmq_definitions(original_definitions_dump_file).with(
          :user      => rabbit_hash['user'],
          :password  => rabbit_hash['password'],
          :url       => rabbit_api_endpoint,
      )
      should contain_exec('rabbitmq-dump-clean').with(
          :refreshonly => true,
      )
      ['/etc/rabbitmq/definitions', '/etc/rabbitmq/definitions.full'].each do |f|
        should contain_file(f).with(
          :ensure => 'file',
          :owner  => 'root',
          :group  => 'root',
          :mode   => '0600')
      end
    end
  end
  test_ubuntu_and_centos manifest
end
