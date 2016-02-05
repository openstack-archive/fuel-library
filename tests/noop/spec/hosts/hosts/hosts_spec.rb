require 'spec_helper'
require 'shared-examples'
manifest = 'hosts/hosts.pp'

describe manifest do
  shared_examples 'catalog' do

    network_metadata = task.hiera_structure('network_metadata/nodes')
    messaging_fqdn_prefix = task.hiera('node_name_prefix_for_messaging', 'messaging-')

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

