# require 'puppet'
# require 'rspec'
# require 'rspec-puppet'
require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'
require 'json'
require 'yaml'
#require 'puppet/parser/functions/lib/sanitize_bool_in_hash.rb'


class NeutronConfig
  def initialize(init_v)
    @def_v = {}
    @def_v.replace(init_v)
    # ::L23network::Scheme.set = {
    #   :endpoints => {
    #     :eth0 => {
    #       :IP =>  'dhcp',
    #     },
    #     :'br-ex' => {
    #       :gateway => '10.1.3.1',
    #       :IP => ['10.1.3.11/24'],
    #     },
    #     :'br-mgmt' => {
    #       :IP => ['10.20.1.2/24'],
    #     },
    #     :'br-storage' => {
    #       :IP => ['192.168.1.2/24'],
    #     },
    #     :'br-prv' => {
    #       :IP => 'none',
    #     },
    #   },
    #   :roles => {
    #     :management =>  'br-mgmt',
    #     :private => 'br-prv',
    #     :ex =>  'br-ex',
    #     :storage =>  'br-storage',
    #     :admin =>  'eth0',
    #   },
    # }
    @def_config = {
      'rabbit' => {
        'password' => 'nova'
      },
      'nova' => {
        'user_password' => 'nova_user_passwd'
      },
      'neutron_settings' => {
        'amqp' => {
          'provider' => "rabbitmq",
          'username' => "nova",
          'passwd' => "nova",
          'hosts' => "#{@def_v[:management_vip]}:5672",
          'port' => "5672",
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
          'read_timeout' => 60,
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
          'provider' => "ovs",
          'base_mac' => "fa:16:3e:00:00:00",
          'mac_generation_retries' => 32,
          'segmentation_type' => "gre",
          'tunnel_id_ranges' => "3000:65535",
          'phys_nets' => {
            'physnet1' => {
              'bridge' => "br-ex",
              'vlan_range' => nil,
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
          'allow_overlapping_ips' => true,
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
            'tenant' => 'admin',
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
              'enable_dhcp'=>false
            },
          },
          'net04' => {
            'shared' => false,
            'tenant' => 'admin',
            'L2' => {
              'router_ext'   => false,
              'network_type' => 'gre', # or vlan
              'physnet'      => nil,
              'segment_id'   => nil,
            },
            'L3' => {
              'subnet' => "192.168.111.0/24",
              'gateway' => "192.168.111.1",
              'nameservers' => ["8.8.4.4", "8.8.8.8"],
              'floating' => nil,
              'enable_dhcp'=>true
            },
          },
        },
        'polling_interval' => 2,
        'root_helper' => "sudo neutron-rootwrap /etc/neutron/rootwrap.conf",
      },
    }
    @def_config['neutron_settings']['keystone']['auth_url'] = "http://#{@def_v[:management_vip]}:35357/v2.0"
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

describe 'sanitize_neutron_config with minimal incoming data' , :type => :puppet_function do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  let(:cfg) { {
      'deployment_mode' => 'ha_compact',
      'access' => {
        'password' => 'passwd__admin',
        'user'     => 'user__admin',
        'tenant'   => 'tenant__admin',
        'email'    => 'admin@example.org',
      },
      'nova' => {
        'user_password' => 'nova_user_passwd'
      },
      'neutron_settings' => {
        'amqp' => {
          'hosts' => '192.168.0.254:5672',
          'passwd' => "nova",
        },
        'database' => {
          'host' => '192.168.0.254',
        },
        'keystone' => {
          'auth_host' => '192.168.0.254',
        },
        'metadata' => {
          'nova_metadata_ip' => '192.168.0.254',
        },
      },
      'nodes' => [{
        'storage_netmask' => '255.255.255.0',
        'uid' => '1',
        'public_netmask' => '255.255.255.0',
        'swift_zone' => '1',
        'internal_address' => '192.168.0.2',
        'fqdn' => 'node-1.domain.tld',
        'name' => 'node-1',
        'internal_netmask' => '255.255.255.0',
        'storage_address' => '192.168.1.2',
        'role' => 'primary-controller',
        'public_address' => '10.22.3.2',
      },{
        'storage_netmask' => '255.255.255.0',
        'uid' => '2',
        'public_netmask' => '255.255.255.0',
        'swift_zone' => '2',
        'internal_address' => '192.168.0.3',
        'fqdn' => 'node-2.domain.tld',
        'name' => 'node-2',
        'internal_netmask' => '255.255.255.0',
        'storage_address' => '192.168.1.3',
        'role' => 'controller',
        'public_address' => '10.22.3.3',
      },{
        'storage_netmask' => '255.255.255.0',
        'uid' => '3',
        'public_netmask' => '255.255.255.0',
        'swift_zone' => '3',
        'internal_address' => '192.168.0.4',
        'fqdn' => 'node-3.domain.tld',
        'name' => 'node-3',
        'internal_netmask' => '255.255.255.0',
        'storage_address' => '192.168.1.4',
        'role' => 'controller',
        'public_address' => '10.22.3.4',
      },{
        'storage_netmask' => '255.255.255.0',
        'uid' => '4',
        'public_netmask' => '255.255.255.0',
        'swift_zone' => '4',
        'internal_address' => '192.168.0.5',
        'fqdn' => 'node-4.domain.tld',
        'name' => 'node-4',
        'internal_netmask' => '255.255.255.0',
        'storage_address' => '192.168.1.5',
        'role' => 'compute',
        'public_address' => '10.22.3.5',
      }],
  } }

  before :each do
    @q_config = NeutronConfig.new({
      :management_vip => '192.168.0.254',
      :management_ip => '192.168.0.11'
    })
    Puppet::Parser::Scope.any_instance.stubs(:function_get_network_role_property).with(['management', 'ipaddr']).returns(@q_config.get_def(:management_ip))
    Puppet::Parser::Scope.any_instance.stubs(:function_get_network_role_property).with(['mesh', 'ipaddr']).returns(@q_config.get_def(:management_ip))
  end

  it 'should exist' do
    Puppet::Parser::Functions.function('sanitize_neutron_config').should == 'function_sanitize_neutron_config'
  end


  it 'should return default config (MAIN SECTION) if given only minimal parameter set' do
    rv = scope.function_sanitize_neutron_config([cfg, 'neutron_settings'])
    rv.delete('L3')
    rv.delete('L2')
    rv.delete('amqp')
    rv.delete('database')
    rv.delete('keystone')
    rv.delete('metadata')
    rv.delete('predefined_networks')
    rv.delete('predefined_routers')
    rv.delete('server')
    expect(rv).to eq({
      "root_helper"=>"sudo neutron-rootwrap /etc/neutron/rootwrap.conf",
      "polling_interval"=>2
    })
  end

  it 'should return default config (AMQP) if given only minimal parameter set' do
    rv = scope.function_sanitize_neutron_config([cfg, 'neutron_settings'])
    expect(rv['amqp']).to eq({
      "provider"=>"rabbitmq",
      "username"=>"nova",
      "passwd"=>"nova",
      "hosts"=>"192.168.0.254:5672",
      "port" => "5673",
      "ha_mode"=>true,
      "control_exchange"=>"neutron",
      "heartbeat"=>60,
      "protocol"=>"tcp",
      "rabbit_virtual_host"=>"/"
    })
  end

  it 'should return default config (DATABASE) if given only minimal parameter set' do
    rv = scope.function_sanitize_neutron_config([cfg, 'neutron_settings'])
    expect(rv['database']).to eq({
      "url"=>"mysql://neutron:neutron@192.168.0.254:3306/neutron?read_timeout=60",
      "provider"=>"mysql",
      "host"=>"192.168.0.254",
      "port"=>3306,
      "database"=>"neutron",
      "username"=>"neutron",
      "passwd"=>"neutron",
      "reconnects"=>-1,
      "reconnect_interval"=>2,
      "read_timeout" => 60,
      "charset"=>nil
    })
  end

  it 'should return default config (L2) if given only minimal parameter set' do
    rv = scope.function_sanitize_neutron_config([cfg, 'neutron_settings'])
    expect(rv['L2']).to eq({
      "provider"=>"ovs",
      "base_mac"=>"fa:16:3e:00:00:00",
      "mac_generation_retries"=>32,
      "segmentation_type"=>"gre",
      "tunnel_id_ranges"=>"3000:65535",
      "phys_bridges"=>["br-ex"],
      "bridge_mappings"=>"physnet1:br-ex",
      "network_vlan_ranges"=>"physnet1",
      "integration_bridge"=>"br-int",
      "tunnel_bridge"=>"br-tun",
      "int_peer_patch_port"=>"patch-tun",
      "tun_peer_patch_port"=>"patch-int",
      "local_ip"=>"192.168.0.11",
      "enable_tunneling"=>true,
      "phys_nets"=>{
        "physnet1"=>{
          "bridge"=>"br-ex",
          "vlan_range"=>nil
        }
      }
    })
  end

  it 'should return default config (KEYSTONE) if given only minimal parameter set' do
    rv = scope.function_sanitize_neutron_config([cfg, 'neutron_settings'])
    expect(rv['keystone']).to eq({
      "auth_region"=>"RegionOne",
      "auth_url"=>"http://192.168.0.254:35357/v2.0",
      "auth_host"=>"192.168.0.254", "auth_port"=>35357,
      "auth_protocol"=>"http",
      "auth_api_version"=>"v2.0",
      "admin_tenant_name"=>"services",
      "admin_user"=>"neutron",
      "admin_password"=>"neutron_pass",
      "admin_email"=>"neutron@localhost",
      "signing_dir"=>"/var/lib/neutron/keystone-signing"
    })
  end

  it 'should return default config (METADATA) if given only minimal parameter set' do
    rv = scope.function_sanitize_neutron_config([cfg, 'neutron_settings'])
    expect(rv['metadata']).to eq({
      "nova_metadata_ip"=>"192.168.0.254",
      "nova_metadata_port"=>8775,
      "metadata_ip"=>"169.254.169.254",
      "metadata_port"=>8775,
      "metadata_proxy_shared_secret"=>"secret-word"
    })
  end

  it 'should return default config (PREDEFINED NETWORKS) if given only minimal parameter set' do
    rv = scope.function_sanitize_neutron_config([cfg, 'neutron_settings'])
    expect(rv['predefined_networks']).to eq({
      "net04_ext"=>{
        "shared"=>false,
        "tenant"=>"tenant__admin",
        "L2"=>{
          "router_ext"=>true,
          "network_type"=>"flat",
          "physnet"=>"physnet1",
          "segment_id"=>nil
        },
        "L3"=>{
          "subnet"=>"10.100.100.0/24",
          "gateway"=>"10.100.100.1",
          "nameservers"=>[],
          "enable_dhcp"=>false,
          "floating"=>"10.100.100.130:10.100.100.254"
        }
      },
      "net04"=>{
        "shared"=>false,
        "tenant"=>"tenant__admin",
        "L2"=>{
          "router_ext"=>false,
          "network_type"=>"gre",
          "physnet"=>nil,
          "segment_id"=>nil
        },
        "L3"=>{
          "subnet"=>"192.168.111.0/24",
          "gateway"=>"192.168.111.1",
          "nameservers"=>["8.8.4.4", "8.8.8.8"],
          "enable_dhcp"=>true,
          "floating"=>nil
        }
      }
    })
  end

  it 'should return default config (PREDEFINED ROUTERS) if given only minimal parameter set' do
    rv = scope.function_sanitize_neutron_config([cfg, 'neutron_settings'])
    expect(rv['predefined_routers']).to eq({
      "router04"=>{
        "tenant"=>"tenant__admin",
        "virtual"=>false,
        "external_network"=>"net04_ext",
        "internal_networks"=>["net04"]
      }
    })
  end

  it 'should return default config (SERVER) if given only minimal parameter set' do
    rv = scope.function_sanitize_neutron_config([cfg, 'neutron_settings'])
    expect(rv['server']).to eq({
      "api_url"=>"http://:9696",    # !!!!!!!!!!!!!!!!!!!!!!!!
      "api_protocol"=>"http",
      "bind_host"=>"192.168.0.11",
      "bind_port"=>9696,
      "agent_down_time"=>15,
      "report_interval"=>5,
      "allow_bulk"=>true,
      "control_exchange"=>"neutron",
      "notify_nova_admin_auth_url" => "http://192.168.0.254:35357/v2.0",
      "notify_nova_admin_password" => "nova_user_passwd",
      "notify_nova_admin_tenant_id" => "service_tenant_id",
      "notify_nova_admin_username" => "nova",
      "notify_nova_api_url" => "http://:8474/v2",
      "notify_nova_on_port_data_changes" => true,
      "notify_nova_on_port_status_changes" => true,
      "notify_nova_send_events_interval" => 2
    })
  end
end



describe 'sanitize_neutron_config' , :type => :puppet_function do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  before :each do
    @q_config = NeutronConfig.new({
      :management_vip => '192.168.0.254',
      :management_ip => '192.168.0.11',
      :nodes => [
        {:name=>'node-1', :internal_address=>'192.168.0.3', :role=>'primary-controller'},
        {:name=>'node-2', :internal_address=>'192.168.0.4', :role=>'controller'},
        {:name=>'node-3', :internal_address=>'192.168.0.5', :role=>'controller'},

      ]
    })
    Puppet::Parser::Scope.any_instance.stubs(:function_get_network_role_property).with(['management', 'ipaddr']).returns(@q_config.get_def(:management_ip))
    Puppet::Parser::Scope.any_instance.stubs(:function_get_network_role_property).with(['mesh', 'ipaddr']).returns(@q_config.get_def(:management_ip))
    @cfg = @q_config.get_def_config()
    cfg_q = @cfg['neutron_settings']
    @res_cfg = Marshal.load(Marshal.dump(cfg_q))
    @res_cfg['L2']['enable_tunneling'] = true
  end

  it 'should exist' do
    Puppet::Parser::Functions.function('sanitize_neutron_config').should == 'function_sanitize_neutron_config'
  end

  # it 'should return default config if incoming hash is empty' do
  #   @res_cfg['database']['url'] = 'mysql://neutron:neutron@192.168.0.254:3306/neutron'
  #   should run.with_params({},'neutron_settings').and_return(@res_cfg)
  # end

  it 'should return default config for GRE if default config given as incoming' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['neutron_settings']['L2']['segmentation_type'] = 'gre'
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['L2']['segmentation_type'] = 'gre'
    #res_cfg['L2']['enable_tunneling'] = true
    res_cfg['L2']['phys_bridges'] = ["br-ex"]
    res_cfg['L2']['network_vlan_ranges'] = "physnet1"
    res_cfg['L2']['bridge_mappings'] = "physnet1:br-ex"
    res_cfg['L2']['phys_nets'] = {
      "physnet1" => {
        "bridge" => "br-ex",
        "vlan_range" => nil
      }
    }
    res_cfg['predefined_networks']['net04']['L2']['physnet'] = nil
    res_cfg['database']['url'] = 'mysql://neutron:neutron@192.168.0.254:3306/neutron?read_timeout=60'
    rv = scope.function_sanitize_neutron_config([cfg, 'neutron_settings'])
    expect(rv).to eq(res_cfg)
  end

  it 'should substitute default values if missing required field in config (amqp)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['neutron_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['database']['url'] = 'mysql://neutron:neutron@192.168.0.254:3306/neutron?read_timeout=60'
    rv = scope.function_sanitize_neutron_config([@cfg, 'neutron_settings'])
    expect(rv['amqp']).to eq(res_cfg['amqp'])
  end

  it 'should substitute default values if missing required field in config (database)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['neutron_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['database']['url'] = 'mysql://neutron:neutron@192.168.0.254:3306/neutron?read_timeout=60'
    rv = scope.function_sanitize_neutron_config([cfg, 'neutron_settings'])
    expect(rv['database']).to eq res_cfg['database']
  end

  it 'should substitute default values if missing required field in config (server)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['neutron_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['database']['url'] = 'mysql://neutron:neutron@192.168.0.254:3306/neutron?read_timeout=60'
    rv = scope.function_sanitize_neutron_config([@cfg, 'neutron_settings'])
    expect(rv['server']).to eq res_cfg['server']
  end

  it 'should substitute default values if missing required field in config (keystone)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['neutron_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['database']['url'] = 'mysql://neutron:neutron@192.168.0.254:3306/neutron?read_timeout=60'
    rv = scope.function_sanitize_neutron_config([@cfg, 'neutron_settings'])
    expect(rv['keystone']).to eq res_cfg['keystone']
  end

  it 'should substitute default values if missing required field in config (L2)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['neutron_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['L2']['enable_tunneling'] = true
    res_cfg['L2']['phys_bridges'] = ["br-ex"]
    res_cfg['L2']['network_vlan_ranges'] = "physnet1"
    res_cfg['L2']['bridge_mappings'] = "physnet1:br-ex"
    res_cfg['L2']['phys_nets'] = {
      "physnet1" => {
        "bridge" => "br-ex",
        "vlan_range" => nil
      }
    }
    res_cfg['database']['url'] = 'mysql://neutron:neutron@192.168.0.254:3306/neutron?read_timeout=60'
    rv = scope.function_sanitize_neutron_config([@cfg, 'neutron_settings'])
    expect(rv['L2']).to eq res_cfg['L2']
  end

  it 'should substitute default values if missing required field in config (L3)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['neutron_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['database']['url'] = 'mysql://neutron:neutron@192.168.0.254:3306/neutron?read_timeout=60'
    rv = scope.function_sanitize_neutron_config([@cfg, 'neutron_settings'])
    expect(rv['L3']).to eq res_cfg['L3']
  end

  it 'should substitute default values if missing required field in config (predefined_networks)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['neutron_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['predefined_networks']['net04']['L2']['physnet'] = nil
    res_cfg['database']['url'] = 'mysql://neutron:neutron@192.168.0.254:3306/neutron?read_timeout=60'
    rv = scope.function_sanitize_neutron_config([@cfg, 'neutron_settings'])
    expect(rv['predefined_networks']).to eq res_cfg['predefined_networks']
  end

  it 'should substitute default values if missing required field in config (predefined_routers)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['neutron_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['database']['url'] = 'mysql://neutron:neutron@192.168.0.254:3306/neutron?read_timeout=60'
    rv = scope.function_sanitize_neutron_config([@cfg, 'neutron_settings'])
    expect(rv['predefined_routers']).to eq res_cfg['predefined_routers']
  end

  it 'should calculate database url if database properties not given' do
    @cfg['neutron_settings']['database'] = {}
    rv = scope.function_sanitize_neutron_config([@cfg, 'neutron_settings'])
    expect(rv['database']['url']).to eq "mysql://neutron:neutron@192.168.0.254:3306/neutron?read_timeout=60"
  end
  it 'should calculate database url if some database properties given' do
    @cfg['neutron_settings']['database'] = {
      'provider' => 'mysql',
      'database' => 'qq_database',
      'username' => 'qq_username',
      'passwd' => 'qq_password',
      'host' => '5.4.3.2',
      'port' => 666,
    }
    rv = scope.function_sanitize_neutron_config([@cfg, 'neutron_settings'])
    expect(rv['database']['url']).to eq "mysql://qq_username:qq_password@5.4.3.2:666/qq_database?read_timeout=60"
  end

  it 'should can substitute values in deep level' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['neutron_settings']['L2']['segmentation_type'] = 'gre'
    cfg['neutron_settings']['amqp']['provider'] = "XXXXXXXXXXxxxx"
    cfg['neutron_settings']['L2']['base_mac'] = "aa:aa:aa:00:00:00"
    cfg['neutron_settings']['L2']['integration_bridge'] = "xx-xxx"
    cfg['neutron_settings']['L2']['local_ip'] = "9.9.9.9"
    res_cfg = Marshal.load(Marshal.dump(cfg['neutron_settings']))
    res_cfg['L2']['segmentation_type'] = 'gre'
    #res_cfg['L2']['enable_tunneling'] = true
    res_cfg['L2']['phys_bridges'] = ["br-ex"]
    res_cfg['L2']['network_vlan_ranges'] = "physnet1"
    res_cfg['L2']['bridge_mappings'] = "physnet1:br-ex"
    res_cfg['L2']['phys_nets'] = {
      "physnet1" => {
        "bridge" => "br-ex",
        "vlan_range" => nil
      }
    }
    res_cfg['predefined_networks']['net04']['L2']['physnet'] = nil
    res_cfg['database']['url'] = 'mysql://neutron:neutron@192.168.0.254:3306/neutron?read_timeout=60'
    res_cfg['L2']['enable_tunneling'] = true
    #should run.with_params(@cfg,'neutron_settings').and_return(res_cfg)
    rv = scope.function_sanitize_neutron_config([cfg, 'neutron_settings'])
    #expect(rv['L2']).to eq res_cfg['L2']
    #expect(rv['L3']).to eq res_cfg['L3']
    #expect(rv['predefined_networks']).to eq res_cfg['predefined_networks']
    expect(rv).to eq res_cfg
  end

  it 'should calculate hostname if amqp host not given' do
    @cfg['neutron_settings']['amqp'] = {
          'provider' => "rabbitmq",
    }
    rv = scope.function_sanitize_neutron_config([@cfg, 'neutron_settings'])
    erv = @res_cfg['amqp']
    erv["port"] = "5672"
    erv["hosts"] = "192.168.0.3:5672,192.168.0.4:5672,192.168.0.5:5672"
    expect(rv['amqp']).to eq erv
  end

  it 'should calculate auth url if auth properties not given' do
    @cfg['neutron_settings']['keystone'] = {}
    rv = scope.function_sanitize_neutron_config([@cfg, 'neutron_settings'])
    expect(rv['keystone']['auth_url']).to eq "http://192.168.0.254:35357/v2.0"
  end

  it 'should calculate auth url if some auth properties given' do
    @cfg['neutron_settings']['keystone'] = {
          'auth_host' => "1.2.3.4",
          'auth_port' => 666,
          'auth_region' => 'RegionOne',
          'auth_protocol' => "https",
          'auth_api_version' => "v10.0",
          'admin_tenant_name' => "xxXXxx",
          'admin_user' => "user_q",
          'admin_password' => "pass_q",
          'admin_email' => "test.neutron@localhost",
    }
    rv = scope.function_sanitize_neutron_config([@cfg, 'neutron_settings'])
    expect(rv['keystone']['auth_url']).to eq "https://1.2.3.4:666/v10.0"
  end

  it 'enable_tunneling must be True if segmentation_type is GRE' do
    @cfg['neutron_settings']['L2']['segmentation_type'] = 'gre'
    rv = scope.function_sanitize_neutron_config([@cfg, 'neutron_settings'])
    expect(rv['L2']['enable_tunneling']).to eq true
  end
  it 'enable_tunneling must be False if segmentation_type is VLAN' do
    @cfg['neutron_settings']['L2']['segmentation_type'] = 'vlan'
    rv = scope.function_sanitize_neutron_config([@cfg, 'neutron_settings'])
    expect(rv['L2']['enable_tunneling']).to eq false
  end
end


require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/puppet/parser/functions/sanitize_neutron_config.rb"

describe MrntNeutron do
  describe '.get_keystone_auth_url' do
    it 'should return right auth url' do
      MrntNeutron.get_keystone_auth_url({
        :auth_protocol => 'http',
        :auth_host => 'localhost',
        :auth_port => '5000',
        :auth_api_version => 'v2.0'
      }).should == 'http://localhost:5000/v2.0'
    end
  end

  describe '.get_amqp_config' do
    it 'should return hash with amqp hosts declaration as string for HA mode' do
      MrntNeutron.get_amqp_config({
        :provider => 'rabbitmq',
        :hosts => "1.2.3.4:567  ,  2.3.4.5:678, 3.4.5.6,4.5.6.7:890",
        :port => 555,
        :ha_mode => true,
      }).should == {
        :ha_mode => true,
        :hosts => "1.2.3.4:567,2.3.4.5:678,3.4.5.6:555,4.5.6.7:890",
        :port => 555,
        :provider => "rabbitmq"
      }
    end
  end
  describe '.get_amqp_config' do
    it 'should return hash with amqp hosts declaration as array of string for HA mode' do
      MrntNeutron.get_amqp_config({
        :provider => 'rabbitmq',
        :hosts => ['1.2.3.4:567', '2.3.4.5:678', '3.4.5.6', '4.5.6.7:890'],
        :port => 555,
        :ha_mode => true,
      }).should == {
        :ha_mode => true,
        :hosts => "1.2.3.4:567,2.3.4.5:678,3.4.5.6:555,4.5.6.7:890",
        :port => 555,
        :provider => "rabbitmq"
      }
    end
  end
  describe '.get_amqp_config' do
    it 'should return hash with amqp hosts declaration as array of string without ports for HA mode' do
      MrntNeutron.get_amqp_config({
        :provider => 'rabbitmq',
        :hosts => ['1.2.3.4', '2.3.4.5', '3.4.5.6', '4.5.6.7'],
        :port => 555,
        :ha_mode => true,
      }).should == {
        :ha_mode => true,
        :hosts => "1.2.3.4:555,2.3.4.5:555,3.4.5.6:555,4.5.6.7:555",
        :port => 555,
        :provider => "rabbitmq"
      }
    end
  end
  describe '.get_amqp_config' do
    it 'should return hash with amqp host declaration as string without port for solo mode' do
      MrntNeutron.get_amqp_config({
        :provider => 'rabbitmq',
        :hosts => '1.2.3.4:567',
        :port => 555,
        :ha_mode => false,
      }).should == {
        :ha_mode => false,
        :hosts => "1.2.3.4",
        :port => 567,
        :provider => "rabbitmq"
      }
    end
  end
  describe '.get_amqp_config' do
    it 'should return hash with amqp host declaration as string without port for solo mode' do
      MrntNeutron.get_amqp_config({
        :provider => 'rabbitmq',
        :hosts => '1.2.3.4',
        :port => 555,
        :ha_mode => false,
      }).should == {
        :ha_mode => false,
        :hosts => "1.2.3.4",
        :port => 555,
        :provider => "rabbitmq"
      }
    end
  end

  describe '.get_database_url' do
    it 'should return database url with charset' do
      MrntNeutron.get_database_url({
        :provider => "mysql",
        :host => "1.2.3.4",
        :port => 3306,
        :database => "q_database",
        :username => "q_username",
        :passwd   => "q_passwd",
        :charset => "xxx32",
      }).should == "mysql://q_username:q_passwd@1.2.3.4:3306/q_database?charset=xxx32"
    end
  end
  describe '.get_database_url' do
    it 'should return database url with read_timeout' do
      MrntNeutron.get_database_url({
        :provider => "mysql",
        :host => "1.2.3.4",
        :port => 3306,
        :database => "q_database",
        :username => "q_username",
        :passwd   => "q_passwd",
        :read_timeout => 45,
      }).should == "mysql://q_username:q_passwd@1.2.3.4:3306/q_database?read_timeout=45"
    end
  end
  describe '.get_database_url' do
    it 'should return database url with charset and read_timeout' do
      gdu = MrntNeutron.get_database_url({
        :provider => "mysql",
        :host => "1.2.3.4",
        :port => 3306,
        :database => "q_database",
        :username => "q_username",
        :passwd   => "q_passwd",
        :charset => "xxx32",
        :read_timeout => 45,
      })
      gdu.should =~ /charset=xxx32/
      gdu.should =~ /read_timeout=45/
      gdu.should =~ /\?/
      gdu.should =~ /\&/
    end
  end
  describe '.get_database_url' do
    it 'should return database url without charset and read_timeout' do
      MrntNeutron.get_database_url({
        :provider => "mysql",
        :host => "1.2.3.4",
        :port => 3306,
        :database => "q_database",
        :username => "q_username",
        :passwd   => "q_passwd",
      }).should == "mysql://q_username:q_passwd@1.2.3.4:3306/q_database"
    end
  end
  describe '.get_database_url' do
    it 'should return sqlite url' do
      MrntNeutron.get_database_url({
        :provider => "sqlite",
        :database => "/var/lib/aaa/bbb/ddd.sql",
      }).should == "sqlite:///var/lib/aaa/bbb/ddd.sql"
    end
  end
  describe '.get_database_url' do
    it 'should return sqlite url, with absolute path' do
      MrntNeutron.get_database_url({
        :provider => "sqlite",
        :database => "var/lib/aaa/bbb/ddd.sql",
      }).should == "sqlite:///var/lib/aaa/bbb/ddd.sql"
    end
  end

  describe '.get_bridge_mappings' do
    it 'should return string with mapping bridges to OS internal physnets' do
      MrntNeutron.get_bridge_mappings({
        :phys_nets => {
          :physnet1 => {
            :bridge => "br-ex",
            :vlan_range => nil,
          },
          :physnet2 => {
            :bridge => "br-prv",
            :vlan_range => "3000:4094",
          },
          :physnet3 => {
            :bridge => "br-xxx",
            :vlan_range => "555:666",
          },
        }
      }).should == "physnet1:br-ex,physnet2:br-prv,physnet3:br-xxx"
    end
  end

  describe '.get_network_vlan_ranges' do
    it 'should return string with mapping vlan-IDs OS internal physnets' do
      MrntNeutron.get_network_vlan_ranges({
        :phys_nets => {
          :physnet1 => {
            :bridge => "br-ex",
            :vlan_range => nil,
          },
          :physnet2 => {
            :bridge => "br-prv",
            :vlan_range => "3000:4094",
          },
          :physnet3 => {
            :bridge => "br-xxx",
            :vlan_range => "555:666",
          },
        }
      }).should == "physnet1,physnet2:3000:4094,physnet3:555:666"
    end
  end

  describe '.get_phys_bridges' do
    it 'should return array of using phys_bridges' do
      MrntNeutron.get_phys_bridges({
        :phys_nets => {
          :physnet1 => {
            :bridge => "br-ex",
            :vlan_range => nil,
          },
          :physnet2 => {
            :bridge => "br-prv",
            :vlan_range => "3000:4094",
          },
          :physnet3 => {
            :bridge => "br-xxx",
            :vlan_range => "555:666",
          },
        }
      }).should == ['br-ex','br-prv','br-xxx']
    end
  end
end

# vim: set ts=2 sw=2 et :
