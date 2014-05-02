# require 'puppet'
# require 'rspec'
# require 'rspec-puppet'
require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'
require 'json'
require 'yaml'

class NeutronNRConfig
  def initialize(init_v)
    @def_v = {}
    @def_v.replace(init_v)
    @def_config = {
        'amqp' => {
          'provider' => "rabbitmq",
          'username' => "nova",
          'passwd' => "nova",
          'hosts' => "#{@def_v[:management_vip]}:5672",
          'control_exchange' => "neutron",
          'heartbeat' => 60,
          'protocol' => "tcp",
          'rabbit_virtual_host' => "/",
          'ha_mode' => true,
        },
        'database' => {
          'provider' => "mysql",
          'host' => "#{@def_v[:management_vip]}",
          'port' => 3306,
          'database' => "neutron",
          'username' => "neutron",
          'passwd'   => "neutron",
          'reconnects' => -1,
          'reconnect_interval' => 2,
          'url'  => nil,
          'charset' => nil,
        },
        'keystone' => {
          'auth_host' => "#{@def_v[:management_vip]}",
          'auth_port' => 35357,
          'auth_region' => 'RegionOne',
          'auth_protocol' => "http",
          'auth_api_version' => "v2.0",
          'admin_tenant_name' => "services",
          'admin_user' => "neutron",
          'admin_password' => "neutron_pass",
          'admin_email' => "neutron@localhost",
          'signing_dir' => "/var/lib/neutron/keystone-signing",
        },
        'server' => {
          'api_url' => "http://#{@def_v[:management_vip]}:9696",
          'api_protocol' => "http",
          'bind_host' => "#{@def_v[:management_vip]}",
          'bind_port' => 9696,
          'agent_down_time' => 15,
          'report_interval' => 5,
          'allow_bulk'      => true,
          'control_exchange'=> 'neutron',
        },
        'metadata' => {
          'nova_metadata_ip' => "#{@def_v[:management_vip]}",
          'nova_metadata_port' => 8775,
          'metadata_ip' => "169.254.169.254",
          'metadata_port' => 8775,
          'metadata_proxy_shared_secret' => "secret-word",
        },
        'L2' => {
          'base_mac' => "fa:16:3e:00:00:00",
          'mac_generation_retries' => 32,
          'segmentation_type' => "gre",
          'enable_tunneling'=>true,
          'tunnel_id_ranges' => "3000:65535",
          'phys_nets' => {
            'physnet1' => {
              'bridge' => "br-ex",
              'vlan_range' => nil,
            },
            'physnet2' => {
              'bridge' => "br-prv",
              'vlan_range' => "3000:4094",
            },
          },
          'phys_bridges' => ['br-ex', 'br-prv'],
          'bridge_mappings' => "physnet1:br-ex,physnet2:br-prv",
          'network_vlan_ranges' => "physnet1,physnet2:3000:4094",
          'integration_bridge' => "br-int",
          'tunnel_bridge' => "br-tun",
          'int_peer_patch_port' => "patch-tun",
          'tun_peer_patch_port' => "patch-int",
          'local_ip' => "#{@def_v[:management_ip]}",
        },
        'L3' => {
          'router_id' => nil,
          'gateway_external_network_id' => nil,
          'use_namespaces' => true,
          'allow_overlapping_ips' => false,
          'network_auto_schedule' => true,
          'router_auto_schedule'  => true,
          'public_bridge' => "br-ex",
          'send_arp_for_ha' => 8,
          'resync_interval' => 40,
          'resync_fuzzy_delay' => 5,
          'dhcp_agent' => {
            'enable_isolated_metadata' => false,
            'enable_metadata_network' => false,
            'lease_duration' => 120
          }
        },
        'predefined_routers' => {
          'router04' => {
            'tenant' => 'admin',
            'virtual' => false,
            'external_network' => "net04_ext",
            'internal_networks' => ["net04"],
          }
        },
        'predefined_networks' => {
          'net04_ext' => {
            'shared' => false,
            'L2' => {
              'router_ext'   => true,
              'network_type' => 'flat',
              'physnet'      => 'physnet1',
              'segment_id'   => nil,
            },
            'L3' => {
              'subnet' => "10.100.100.0/24",
              'gateway' => "10.100.100.1",
              'nameservers' => [],
              'floating' => "10.100.100.130:10.100.100.254",
            },
          },
          'net04' => {
            'shared' => false,
            'L2' => {
              'router_ext'   => false,
              'network_type' => 'gre', # or vlan
              'physnet'      => 'physnet2',
              'segment_id'   => nil,
            },
            'L3' => {
              'subnet' => "192.168.111.0/24",
              'gateway' => "192.168.111.1",
              'nameservers' => ["8.8.4.4", "8.8.8.8"],
              'floating' => nil,
            },
          },
        },
        'polling_interval' => 2,
        'root_helper' => "sudo neutron-rootwrap /etc/neutron/rootwrap.conf"
    }
    @def_config['keystone']['auth_url'] = "http://#{@def_v[:management_vip]}:35357/v2.0"
    init_v.each() do |k,v|
      @def_config[k.to_s()] = v
    end
  end

  def get_def_config()
    return Marshal.load(Marshal.dump(@def_config))
  end

  def get_def(k)
    return @def_v[k]
  end

  # def get_config(mix)
  #   cfg = {}
  #   cfg.replace(@def_config)
  # end

end

describe 'create_predefined_networks_and_routers' , :type => :puppet_function do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  before :each do
    # node      = Puppet::Node.new("floppy", :environment => 'production')
    # @compiler = Puppet::Parser::Compiler.new(node)
    # @scope    = Puppet::Parser::Scope.new(@compiler)
    # @topscope = @scope.compiler.topscope
    # @scope.parent = @topscope
    # Puppet::Parser::Functions.function(:create_resources)
    @qnr_config = NeutronNRConfig.new({
      :management_vip => '192.168.0.254',
      :management_ip => '192.168.0.11'
    })
    # Puppet::Parser::Scope.any_instance.stubs(:function_get_network_role_property).with('management', 'ipaddr').returns(@q_config.get_def(:management_ip))
    @cfg = @qnr_config.get_def_config()
    cfg_q = @cfg['neutron_settings']
    # @res_cfg = Marshal.load(Marshal.dump(cfg_q))
  end

  it 'should exist' do
    Puppet::Parser::Functions.function('create_predefined_networks_and_routers').should == 'function_create_predefined_networks_and_routers'
  end


  # it 'should calculate auth url if auth properties not given' do
  #   @cfg['neutron_settings']['keystone'] = {}
  #   subject.call([@cfg, 'neutron_settings'])['keystone']['auth_url'].should  == "http://192.168.0.254:35357/v2.0"
  # end
  # it 'should calculate auth url if some auth properties given' do
  #   @cfg['neutron_settings']['keystone'] = {
  #         'auth_host' => "1.2.3.4",
  #         'auth_port' => 666,
  #         'auth_region' => 'RegionOne',
  #         'auth_protocol' => "https",
  #         'auth_api_version' => "v10.0",
  #         'admin_tenant_name' => "xxXXxx",
  #         'admin_user' => "user_q",
  #         'admin_password' => "pass_q",
  #         'admin_email' => "test.neutron@localhost",
  #   }
  #   subject.call([@cfg, 'neutron_settings'])['keystone']['auth_url'].should  == "https://1.2.3.4:666/v10.0"
  # end

  # it 'enable_tunneling must be True if segmentation_type is GRE' do
  #   @cfg['neutron_settings']['L2']['segmentation_type'] = 'gre'
  #   subject.call([@cfg, 'neutron_settings'])['L2']['enable_tunneling'].should  == true
  # end
  # it 'enable_tunneling must be False if segmentation_type is VLAN' do
  #   @cfg['neutron_settings']['L2']['segmentation_type'] = 'vlan'
  #   subject.call([@cfg, 'neutron_settings'])['L2']['enable_tunneling'].should  == false
  # end

end

# vim: set ts=2 sw=2 et :
