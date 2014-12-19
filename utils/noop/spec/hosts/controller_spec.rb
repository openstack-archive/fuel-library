require 'spec_helper'
require 'yaml'
require 'shared-examples'

manifest = 'controller.pp'
manifest_dir = '/etc/puppet/modules/osnailyfacter/modular'

astute_filename = Noop.astute_yaml_name
settings = YAML.load_file(Noop.astute_yaml_path)
node = settings['fqdn']

# Check if this task is enabled for the astute.yaml
if settings['tasks'].map { |n| n['parameters']['puppet_manifest'] }.include?("#{manifest_dir}/#{manifest}")
  describe manifest do
    let :facts do
      Noop.facts
    end

    before :all do
      Noop.set_manifest manifest
    end

    ########################################
    # Tests for node as a shared example
    shared_examples "puppet catalogue" do
      internal_address = settings['nodes'].find{|n| n['fqdn'] == node}['internal_address']
      rabbit_user = settings['rabbit']['user'] || 'nova'
      use_neutron = settings['quantum'].to_s
      role = settings['role']
      rabbit_ha_queues = 'true'
      primary_controller_nodes = filter_nodes(settings['nodes'],'role','primary-controller')
      controllers = primary_controller_nodes + filter_nodes(settings['nodes'],'role','controller')
      controller_internal_addresses = nodes_to_hash(controllers,'name','internal_address')
      controller_nodes = ipsort(controller_internal_addresses.values)
      memcached_servers = controller_nodes.map{ |n| n = n + ':11211' }.join(',')
      horizon_bind_address = internal_address

      # Test that catalog compiles and there are no dependency cycles in the graph
      it { should compile }

      # Tests for controller roles
      if ( role == 'primary-controller' )
        it_behaves_like 'primary controller with swift'
      end
      it_behaves_like 'controller with keystone', settings['keystone']['admin_token'], memcached_servers
      it_behaves_like 'controller with horizon', settings['nova_quota'], horizon_bind_address
      it_behaves_like 'ha controller with swift'

      if settings['ceilometer']['enabled']
        it_behaves_like 'controller with ceilometer', rabbit_user, settings['rabbit']['password'], use_neutron, rabbit_ha_queues
      end

      if settings['quantum']
        it_behaves_like 'controller with neutron'
      end

      # Tests for plugins
      if settings['sahara']['enabled']
        it_behaves_like 'node with sahara', settings['sahara']['db_password'],  settings['sahara']['user_password'], use_neutron, rabbit_ha_queues
      end
      if settings['murano']['enabled']
        it_behaves_like 'node with murano', rabbit_user, settings['rabbit']['password'], use_neutron
      end

    end # end of shared_examples

    #######################################
    # Testing on different operating systems
    # Ubuntu
    context 'on Ubuntu platforms' do
      before do
        Noop.facts.merge!( :osfamily => 'Debian' )
        Noop.facts.merge!( :lsbdistid => 'Ubuntu' )
        Noop.facts.merge!( :operatingsystem => 'Ubuntu' )
        Noop.facts.merge!( :operatingsystemrelease => '12.04' )
      end
      it_behaves_like "puppet catalogue"
    end

    # CentOS
    context 'on CentOS platforms' do
      before do
        Noop.facts.merge!( :osfamily => 'RedHat' )
        Noop.facts.merge!( :lsbdistid => 'CentOS' )
        Noop.facts.merge!( :operatingsystem => 'CentOS' )
        Noop.facts.merge!( :operatingsystemrelease => '6.5' )
      end
      it_behaves_like "puppet catalogue"
    end

  end # end of describe
end
