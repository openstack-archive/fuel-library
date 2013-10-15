require 'spec_helper'
require 'json'
require 'yaml'
#require 'puppet/parser/functions/lib/sanitize_bool_in_hash.rb'


class QuantumConfig
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
      'quantum_settings' => {
        'amqp' => {
          'provider' => "rabbitmq",
          'username' => "nova",
          'passwd' => "nova",
          'hosts' => "#{@def_v[:management_vip]}:5672",
          'control_exchange' => "quantum",
          'heartbeat' => 60,
          'protocol' => "tcp",
          'rabbit_virtual_host' => "/",
          'ha_mode' => true,
        },
        'database' => {
          'provider' => "mysql",
          'host' => "#{@def_v[:management_vip]}",
          'port' => 3306,
          'database' => "quantum",
          'username' => "quantum",
          'passwd'   => "quantum",
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
          'admin_user' => "quantum",
          'admin_password' => "quantum_pass",
          'admin_email' => "quantum@localhost",
          'signing_dir' => "/var/lib/quantum/keystone-signing",
        },
        'server' => {
          'api_url' => "http://#{@def_v[:management_vip]}:9696",
          'api_protocol' => "http",
          'bind_host' => "#{@def_v[:management_vip]}",
          'bind_port' => 9696,
          'agent_down_time' => 15,
          'allow_bulk'      => true,
          'control_exchange'=> 'quantum',
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
              'physnet'      => 'physnet2',
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
        'root_helper' => "sudo quantum-rootwrap /etc/quantum/rootwrap.conf",
      },
    }
    @def_config['quantum_settings']['keystone']['auth_url'] = "http://#{@def_v[:management_vip]}:35357/v2.0"
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

describe 'sanitize_quantum_config' , :type => :puppet_function do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  before :each do
    # node      = Puppet::Node.new("floppy", :environment => 'production')
    # @compiler = Puppet::Parser::Compiler.new(node)
    # @scope    = Puppet::Parser::Scope.new(@compiler)
    # @topscope = @scope.compiler.topscope
    # @scope.parent = @topscope
    # Puppet::Parser::Functions.function(:create_resources)
    @q_config = QuantumConfig.new({
      :management_vip => '192.168.0.254',
      :management_ip => '192.168.0.11'
    })
    Puppet::Parser::Scope.any_instance.stubs(:function_get_network_role_property).with(['management', 'ipaddr']).returns(@q_config.get_def(:management_ip))
    Puppet::Parser::Scope.any_instance.stubs(:function_get_network_role_property).with(['mesh', 'ipaddr']).returns(@q_config.get_def(:management_ip))
    @cfg = @q_config.get_def_config()
    cfg_q = @cfg['quantum_settings']
    @res_cfg = Marshal.load(Marshal.dump(cfg_q))
    @res_cfg['L2']['enable_tunneling'] = true
  end

  it 'should exist' do
    Puppet::Parser::Functions.function('sanitize_quantum_config').should == 'function_sanitize_quantum_config'
  end

  # it 'should return default config if incoming hash is empty' do
  #   @res_cfg['database']['url'] = 'mysql://quantum:quantum@192.168.0.254:3306/quantum'
  #   should run.with_params({},'quantum_settings').and_return(@res_cfg)
  # end

  it 'should return default config if default config given as incoming' do
    @res_cfg['database']['url'] = 'mysql://quantum:quantum@192.168.0.254:3306/quantum'
    should run.with_params(@cfg,'quantum_settings').and_return(@res_cfg)
  end

  it 'should substitute default values if missing required field in config (amqp)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['quantum_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['database']['url'] = 'mysql://quantum:quantum@192.168.0.254:3306/quantum'
    subject.call([@cfg, 'quantum_settings'])['amqp'].should  == res_cfg['amqp']
  end

  it 'should substitute default values if missing required field in config (database)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['quantum_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['database']['url'] = 'mysql://quantum:quantum@192.168.0.254:3306/quantum'
    subject.call([@cfg, 'quantum_settings'])['database'].should  == res_cfg['database']
  end

  it 'should substitute default values if missing required field in config (server)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['quantum_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['database']['url'] = 'mysql://quantum:quantum@192.168.0.254:3306/quantum'
    subject.call([@cfg, 'quantum_settings'])['server'].should  == res_cfg['server']
  end

  it 'should substitute default values if missing required field in config (keystone)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['quantum_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['database']['url'] = 'mysql://quantum:quantum@192.168.0.254:3306/quantum'
    subject.call([@cfg, 'quantum_settings'])['keystone'].should  == res_cfg['keystone']
  end

  it 'should substitute default values if missing required field in config (L2)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['quantum_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['database']['url'] = 'mysql://quantum:quantum@192.168.0.254:3306/quantum'
    subject.call([@cfg, 'quantum_settings'])['L2'].should  == res_cfg['L2']
  end

  it 'should substitute default values if missing required field in config (L3)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['quantum_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['database']['url'] = 'mysql://quantum:quantum@192.168.0.254:3306/quantum'
    subject.call([@cfg, 'quantum_settings'])['L3'].should  == res_cfg['L3']
  end

  it 'should substitute default values if missing required field in config (predefined_networks)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['quantum_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['database']['url'] = 'mysql://quantum:quantum@192.168.0.254:3306/quantum'
    subject.call([@cfg, 'quantum_settings'])['predefined_networks'].should  == res_cfg['predefined_networks']
  end

  it 'should substitute default values if missing required field in config (predefined_routers)' do
    cfg = Marshal.load(Marshal.dump(@cfg))
    cfg['quantum_settings']['L3'].delete('dhcp_agent')
    res_cfg = Marshal.load(Marshal.dump(@res_cfg))
    res_cfg['database']['url'] = 'mysql://quantum:quantum@192.168.0.254:3306/quantum'
    subject.call([@cfg, 'quantum_settings'])['predefined_routers'].should  == res_cfg['predefined_routers']
  end

  it 'should calculate database url if database properties not given' do
    @cfg['quantum_settings']['database'] = {}
    subject.call([@cfg, 'quantum_settings'])['database']['url'].should  == "mysql://quantum:quantum@192.168.0.254:3306/quantum"
  end
  it 'should calculate database url if some database properties given' do
    @cfg['quantum_settings']['database'] = {
      'provider' => 'mysql',
      'database' => 'qq_database',
      'username' => 'qq_username',
      'passwd' => 'qq_password',
      'host' => '5.4.3.2',
      'port' => 666,
    }
    subject.call([@cfg, 'quantum_settings'])['database']['url'].should  == "mysql://qq_username:qq_password@5.4.3.2:666/qq_database"
  end

  it 'should can substitute values in deep level' do
    @cfg['quantum_settings']['amqp']['provider'] = "XXXXXXXXXXxxxx"
    @cfg['quantum_settings']['L2']['base_mac'] = "aa:aa:aa:00:00:00"
    @cfg['quantum_settings']['L2']['integration_bridge'] = "xx-xxx"
    @cfg['quantum_settings']['L2']['local_ip'] = "9.9.9.9"
    @cfg['quantum_settings']['predefined_networks']['net04_ext']['L3']['nameservers'] = ["127.0.0.1"]
    res_cfg = Marshal.load(Marshal.dump(@cfg['quantum_settings']))
    res_cfg['database']['url'] = 'mysql://quantum:quantum@192.168.0.254:3306/quantum'
    res_cfg['L2']['enable_tunneling'] = true
    #should run.with_params(@cfg,'quantum_settings').and_return(res_cfg)
    subject.call([@cfg, 'quantum_settings']).should  == res_cfg
  end

  it 'should calculate hostname if amqp host not given' do
    @cfg['quantum_settings']['amqp'] = {
          'provider' => "rabbitmq",
    }
    subject.call([@cfg, 'quantum_settings'])['amqp'].should  == @res_cfg['amqp']
  end

  it 'should calculate auth url if auth properties not given' do
    @cfg['quantum_settings']['keystone'] = {}
    subject.call([@cfg, 'quantum_settings'])['keystone']['auth_url'].should  == "http://192.168.0.254:35357/v2.0"
  end
  it 'should calculate auth url if some auth properties given' do
    @cfg['quantum_settings']['keystone'] = {
          'auth_host' => "1.2.3.4",
          'auth_port' => 666,
          'auth_region' => 'RegionOne',
          'auth_protocol' => "https",
          'auth_api_version' => "v10.0",
          'admin_tenant_name' => "xxXXxx",
          'admin_user' => "user_q",
          'admin_password' => "pass_q",
          'admin_email' => "test.quantum@localhost",
    }
    subject.call([@cfg, 'quantum_settings'])['keystone']['auth_url'].should  == "https://1.2.3.4:666/v10.0"
  end

  it 'enable_tunneling must be True if segmentation_type is GRE' do
    @cfg['quantum_settings']['L2']['segmentation_type'] = 'gre'
    subject.call([@cfg, 'quantum_settings'])['L2']['enable_tunneling'].should  == true
  end
  it 'enable_tunneling must be False if segmentation_type is VLAN' do
    @cfg['quantum_settings']['L2']['segmentation_type'] = 'vlan'
    subject.call([@cfg, 'quantum_settings'])['L2']['enable_tunneling'].should  == false
  end
end


require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/puppet/parser/functions/sanitize_quantum_config.rb"

describe MrntQuantum do
  describe '.get_keystone_auth_url' do
    it 'should return right auth url' do
      MrntQuantum.get_keystone_auth_url({
        :auth_protocol => 'http',
        :auth_host => 'localhost',
        :auth_port => '5000',
        :auth_api_version => 'v2.0'
      }).should == 'http://localhost:5000/v2.0'
    end
  end

  describe '.get_amqp_config' do
    it 'should return hash with amqp hosts declaration as string for HA mode' do
      MrntQuantum.get_amqp_config({
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
      MrntQuantum.get_amqp_config({
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
      MrntQuantum.get_amqp_config({
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
      MrntQuantum.get_amqp_config({
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
      MrntQuantum.get_amqp_config({
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
      MrntQuantum.get_database_url({
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
    it 'should return database url without charset' do
      MrntQuantum.get_database_url({
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
      MrntQuantum.get_database_url({
        :provider => "sqlite",
        :database => "/var/lib/aaa/bbb/ddd.sql",
      }).should == "sqlite:///var/lib/aaa/bbb/ddd.sql"
    end
  end
  describe '.get_database_url' do
    it 'should return sqlite url, with absolute path' do
      MrntQuantum.get_database_url({
        :provider => "sqlite",
        :database => "var/lib/aaa/bbb/ddd.sql",
      }).should == "sqlite:///var/lib/aaa/bbb/ddd.sql"
    end
  end

  describe '.get_bridge_mappings' do
    it 'should return string with mapping bridges to OS internal physnets' do
      MrntQuantum.get_bridge_mappings({
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
      MrntQuantum.get_network_vlan_ranges({
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
      MrntQuantum.get_phys_bridges({
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