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
      expect(subject).to contain_class('galera').with(
        'galera_servers' => galera_nodes,
      ).that_comes_before('Osnailyfacter::Mysql_user')
    end

    it "should configure mysql to ignore lost+found directory" do
      expect(subject).to contain_class('galera').with_override_options(
          /"ignore-db-dirs"=>"lost\+found"/
      ).that_comes_before('Osnailyfacter::Mysql_user')
    end

    it { should contain_class('osnailyfacter::mysql_access') }
    it { should contain_class('openstack::galera::status').that_comes_before('Haproxy_backend_status[mysql]') }
    it { should contain_haproxy_backend_status('mysql').that_comes_before('Class[osnailyfacter::mysql_access]') }

    if Noop.hiera('external_lb', false)
      database_vip = Noop.hiera('database_vip', Noop.hiera('management_vip'))
      url = "http://#{database_vip}:49000"
      provider = 'http'
    else
      url = 'http://' + Noop.hiera('service_endpoint').to_s + ':10000/;csv'
      provider = nil
    end

    it {
      should contain_file('/etc/mysql/conf.d/wsrep.cnf').without(
        :content => /.*log_bin=mysql-bin.*/,
      )
    }

    it {
      should contain_haproxy_backend_status('mysql').with(
        :url      => url,
        :provider => provider
      )
    }
  end
  test_ubuntu_and_centos manifest
end

