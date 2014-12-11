require 'spec_helper'
require 'yaml'
require 'shared-examples'

# Load settings from appropriate astute.yaml
astute_filename = File.basename(__FILE__).gsub(/_spec.rb/, '.yaml')
astute_file = File.expand_path(File.join(__FILE__, '..', '..', '..', 'astute.yaml', astute_filename))
settings = YAML.load_file(astute_file)
node = settings['fqdn']

describe node do
  # Facts
  let :facts do
    {
      :fqdn                 => node,
      :processorcount       => '4',
      :astute_settings_yaml => File.read(astute_file),
      :memorysize_mb        => '32138.66',
      :memorysize           => '31.39 GB',
      :kernel               => 'Linux',
      :l3_fqdn_hostname     => node,
      :l3_default_route     => '172.16.1.1',
      :concat_basedir       => '/tmp/',
    }
  end

  # Run tests for controller
  shared_examples 'controller' do
    internal_address = settings['nodes'].find{|n| n['fqdn'] == node}['internal_address']
    primary_controller_nodes = filter_nodes(settings['nodes'],'role','primary-controller')
    controllers = primary_controller_nodes + filter_nodes(settings['nodes'],'role','controller')
    controller_internal_addresses = nodes_to_hash(controllers,'name','internal_address')
    controller_nodes = ipsort(controller_internal_addresses.values)
    memcached_servers = controller_nodes.map{ |n| n = n + ':11211' }.join(',')
    rabbit_ha_queues = 'true'
    rabbit_user = settings['rabbit']['user'] || 'nova'
    use_neutron = 'true'

    it_behaves_like 'controller with keystone', settings['keystone']['admin_token'], memcached_servers
    it_behaves_like 'controller with horizon', settings['nova_quota'], internal_address
    it_behaves_like 'controller with ceilometer', rabbit_user, settings['rabbit']['password'], rabbit_ha_queues
    it_behaves_like 'controller with neutron'
    it_behaves_like 'node with sahara' , settings['sahara']['db_password'],  settings['sahara']['user_password'], use_neutron, rabbit_ha_queues
    it_behaves_like 'node with murano' , rabbit_user, settings['rabbit']['password'], use_neutron
  end

  # Ubuntu
  context 'on Ubuntu platforms' do
    before do
      facts.merge!( :osfamily => 'Debian' )
      facts.merge!( :operatingsystem => 'Ubuntu')
    end
    it_behaves_like 'controller'
  end

  # CentOS
  context 'on CentOS platforms' do
    before do
      facts.merge!( :osfamily => 'RedHat' )
      facts.merge!( :operatingsystem => 'CentOS')
    end
    it_behaves_like 'controller'
  end

end
