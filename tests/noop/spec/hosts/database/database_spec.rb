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

    let(:network_scheme) do
      Noop.hiera_hash('network_scheme', {})
    end

    let(:endpoints) do
      network_scheme.fetch('endpoints', {})
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

    let(:galera_node_address) do
      Noop.puppet_function 'get_network_role_property', 'mgmt/database', 'ipaddr'
    end

    let(:galera_nodes) do
      (Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', database_nodes, 'mgmt/database').values
    end

    let(:primary_controller) do
      Noop.hiera('primary_controller')
    end

    let(:mysql_database_password) do
       Noop.hiera_hash('mysql', {}).fetch('root_password', '')
    end

    let(:status_database_password) do
       Noop.hiera_hash('mysql', {}).fetch('wsrep_password', '')
    end

    let(:galera_node_address) do
      Noop.puppet_function 'get_network_role_property', 'mgmt/database', 'ipaddr'
    end

    let(:management_networks) do
      Noop.puppet_function 'get_routable_networks_for_network_role', network_scheme, 'mgmt/database', ' '
    end

    let(:custom_setup_class) do
      Noop.hiera('mysql_custom_setup_class', 'galera')
    end

    let(:mysql_socket) do
      case custom_setup_class
      when 'percona'
        '/var/lib/mysqld/mysqld.sock'
      when 'percona_packages'
        case facts[:osfamily]
        when 'Debian'
          '/var/run/mysqld/mysqld.sock'
        when 'RedHat'
          '/var/lib/mysql/mysql.sock'
        end
      else
        '/var/run/mysqld/mysqld.sock'
      end
    end

    it 'should contain galera' do
      should contain_class('galera').with(
        :vendor_type => 'MOS',
        :mysql_package_name => 'mysql-server-wsrep-5.6',
        :galera_package_name => 'galera-3',
        :client_package_name => 'mysql-client-5.6',
        :galera_servers => galera_nodes,
        :galera_master => false,
        :mysql_port => '3307',
        :root_password => mysql_database_password,
        :create_root_my_cnf => true,
        :validate_connection => false,
        :status_check => false,
        :wsrep_group_comm_port => '4567',
        :bind_address => '0.0.0.0',
        :local_ip => galera_node_address,
        :wsrep_sst_method => 'xtrabackup-v2'
      )
      # TODO: check the dynamic override options
    end

    it 'should have explicit ordering between LB classes and particular actions' do
      expect(graph).to ensure_transitive_dependency("Class[openstack::galera::status]", "Haproxy_backend_status[mysql]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[mysql]", "Class[osnailyfacter::mysql_access]")
    end

    it 'should setup the /root/.my.cnf' do
      should contain_class('osnailyfacter::mysql_access').with(
        :db_password => mysql_database_password
      )
    end

    it 'should remove package provided wsrep.cnf' do
      should contain_file('/etc/mysql/conf.d/wsrep.cnf').with(
        :ensure => 'absent',
      ).that_comes_before('Service[mysqld]')
    end

    it 'should configure galera check service' do
      should contain_class('openstack::galera::status').with(
        :status_user => 'clustercheck',
        :status_password => status_database_password,
        :status_allow => galera_node_address,
        :backend_host => galera_node_address,
        :backend_port => '3307',
        :backend_timeout => '10',
        :only_from => "127.0.0.1 240.0.0.2 #{management_networks}"
      )
    end

    it 'should configure pacemaker with mysql service' do
      should contain_class('cluster::mysql').with(
        :primary_controller => primary_controller,
        :mysql_user => 'clustercheck',
        :mysql_password => status_database_password,
        :mysql_config => '/etc/mysql/my.cnf',
        :mysql_socket => mysql_socket,
      )
    end

    it "should configure Galera to use mgmt/database network for replication" do
      should contain_class('galera').with(
        'galera_servers' => galera_nodes,
      )
    end

    it "should configure mysql to ignore lost+found directory" do
      should contain_class('galera').with_override_options(
          /"ignore-db-dir"=>"lost\+found"/
      )
    end

    if Noop.hiera('external_lb', false)
      database_vip = Noop.hiera('database_vip', Noop.hiera('management_vip'))
      url = "http://#{database_vip}:49000"
      provider = 'http'
    else
      url = 'http://' + Noop.hiera('service_endpoint').to_s + ':10000/;csv'
      provider = Puppet::Type.type(:haproxy_backend_status).defaultprovider.name
    end

    it 'should exclude mysql binary logging by default' do
      expect(subject).to contain_class('galera').without_override_options(
          /"logbin"=>"mysql-bin"/
      )
    end

    it 'should configure haproxy backend' do
      should contain_haproxy_backend_status('mysql').with(
        :url      => url,
        :provider => provider
      )
    end
  end

  test_ubuntu_and_centos manifest
end

