require 'spec_helper'
require 'shared-examples'
manifest = 'database/database.pp'

describe manifest do
  shared_examples 'catalog' do
    let(:facts) {
      Noop.ubuntu_facts.merge({
        :mounts => '/,/boot,/var/log,/var/lib/glance,/var/lib/mysql'
      })
    }

    let(:endpoints) do
      Noop.hiera('network_scheme', {}).fetch('endpoints', {})
    end

    let(:other_networks) do
      Noop.puppet_function 'direct_networks', endpoints, 'br-mgmt', 'netmask'
    end

    let(:access_networks) do
      access_networks = ['localhost', '127.0.0.1', '240.0.0.0/255.255.0.0'] + other_networks.split(' ')
    end

    let(:database_nodes) do
      Noop.hiera('database_nodes')
    end

    let(:galera_nodes) do
      (Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', database_nodes, 'mgmt/database').values
    end

    it "should declare osnailyfacter::mysql_user with correct other_networks" do
      expect(subject).to contain_class('osnailyfacter::mysql_user').with(
        'user'            => 'root',
        'access_networks' => access_networks,
      ).that_comes_before('Exec[initial_access_config]')
    end

    it "should configure Galera to use mgmt/database network for replication" do
      expect(subject).to contain_class('mysql::server').with(
        'galera_nodes' => galera_nodes,
      ).that_comes_before('Osnailyfacter::Mysql_user')
    end

    it "should configure mysql to ignore lost+found directory" do
      expect(subject).to contain_class('mysql::server').with(
        'ignore_db_dirs' => ['lost+found']
      ).that_comes_before('Osnailyfacter::Mysql_user')
    end

    it { should contain_class('osnailyfacter::mysql_access') }
    it { should contain_class('openstack::galera::status').that_comes_before('Haproxy_backend_status[mysql]') }
    it { should contain_haproxy_backend_status('mysql').that_comes_before('Class[osnailyfacter::mysql_access]') }
    it { should contain_package('socat').that_comes_before('Class[mysql::server]') }

  end
  test_ubuntu_and_centos manifest
end

