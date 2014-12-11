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
    memcached_servers = settings['management_vip'] + ':11211'
    rabbit_ha_queues = 'false'
    rabbit_user = settings['rabbit']['user'] || 'nova'
    use_neutron = 'true'

    it_behaves_like 'controller with keystone', settings['keystone']['admin_token'], memcached_servers
    it_behaves_like 'controller with horizon', settings['nova_quota'], '0.0.0.0'
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
