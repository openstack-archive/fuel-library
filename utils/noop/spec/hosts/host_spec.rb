require 'spec_helper'
require 'yaml'
require 'shared-examples'

astute_path = File.expand_path(File.join(__FILE__, '..', '..', '..', 'astute.yaml'))

# Interate over astute.yaml settings files and run appropriate tests
# from shared-examples depending on node settings.
Dir.foreach(astute_path) do | astute_filename |
  next if astute_filename !~ /.yaml$/

  # Load settings from appropriate astute.yaml
  astute_file = File.expand_path(File.join(astute_path, astute_filename))
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

    #######################################
    # Run tests for node
    shared_examples "node (#{astute_filename})" do
      # Evaluate some needed params
      internal_address = settings['nodes'].find{|n| n['fqdn'] == node}['internal_address']
      rabbit_user = settings['rabbit']['user'] || 'nova'
      use_neutron = settings['quantum'].to_s
      role = settings['role']
      if ( settings['deployment_mode'] == 'ha_compact' )
        rabbit_ha_queues = 'true'
        primary_controller_nodes = filter_nodes(settings['nodes'],'role','primary-controller')
        controllers = primary_controller_nodes + filter_nodes(settings['nodes'],'role','controller')
        controller_internal_addresses = nodes_to_hash(controllers,'name','internal_address')
        controller_nodes = ipsort(controller_internal_addresses.values)
        memcached_servers = controller_nodes.map{ |n| n = n + ':11211' }.join(',')
        horizon_bind_address = internal_address
      else
        rabbit_ha_queues = 'false'
        memcached_servers = settings['management_vip'] + ':11211'
        horizon_bind_address = '0.0.0.0'
      end

      # Test that catalog compiles and there are no dependency cycles in the graph
      it { should compile }

      # Tests for controller roles
      if ( role =~ /controller/ )
        if ( role == 'primary-controller' )
          it_behaves_like 'primary controller with swift'
        end
        it_behaves_like 'controller with keystone', settings['keystone']['admin_token'], memcached_servers
        it_behaves_like 'controller with horizon', settings['nova_quota'], horizon_bind_address
        it_behaves_like 'controller with ceilometer', rabbit_user, settings['rabbit']['password'], use_neutron, rabbit_ha_queues

        if ( settings['deployment_mode'] == 'ha_compact' )
          it_behaves_like 'ha controller with swift'
        end
        # Tests for plugins
        if settings['sahara']['enabled']
          it_behaves_like 'node with sahara', settings['sahara']['db_password'],  settings['sahara']['user_password'], use_neutron, rabbit_ha_queues
        end
        if settings['murano']['enabled']
          it_behaves_like 'node with murano', rabbit_user, settings['rabbit']['password'], use_neutron
        end
      end

      # Tests for computes
      if ( role == 'compute' )
        it_behaves_like 'compute node', use_neutron, internal_address
      end

   end # end of shared_examples

    #######################################
    # Testing on different operating systems
    # Ubuntu
    context 'on Ubuntu platforms' do
      before do
        facts.merge!( :osfamily => 'Debian' )
        facts.merge!( :lsbdistid => 'Ubuntu' )
        facts.merge!( :operatingsystem => 'Ubuntu' )
        facts.merge!( :operatingsystemrelease => '12.04' )
      end
      it_behaves_like "node (#{astute_filename})"
    end

    # CentOS
    context 'on CentOS platforms' do
      before do
        facts.merge!( :osfamily => 'RedHat' )
        facts.merge!( :lsbdistid => 'CentOS' )
        facts.merge!( :operatingsystem => 'CentOS' )
        facts.merge!( :operatingsystemrelease => '6.5' )
      end
      it_behaves_like "node (#{astute_filename})"
    end
  end # end of describe node

end
