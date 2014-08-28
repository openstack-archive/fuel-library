require 'ipaddr'
require 'yaml'
require 'json'
require 'facter'

class MrntNeutron
  def self.sanitize_value(value)
    case value
    when Hash
      sanitize_hash(value)
    when Array
      sanitize_array(value)
    else
      value
    end
  end

  #class method
  def self.sanitize_array(array)
    array.reduce([]) do |rv, value|
      rv << sanitize_value(value)
    end
  end

  #class method
  def self.sanitize_hash(hash)
    rv = {}
    hash.each do |key, value|
      rv[key.to_sym] = sanitize_value(value)
    end
    return rv
  end

  def default_amqp_provider()
    "rabbitmq"
  end

  def default_netmask()
    "/24"
  end

  def get_management_vip()
    @fuel_config[:management_vip]
  end

  def default_amqp_port(prov)
    if prov == 'rabbitmq' and @fuel_config[:deployment_mode] =~ /^ha_/
      '5673'
    else
      '5672'
    end
  end

  def default_amqp_hosts()
    port = default_amqp_port(default_amqp_provider())
    amqp_hosts = @fuel_config[:role] =~ /controller/ ? ['127.0.0.1'] : []
    begin
      @fuel_config[:nodes].each do |node|
        amqp_hosts << node[:internal_address] if node[:role] =~ /controller/
      end
    rescue
      amqp_hosts = []
    end
    if amqp_hosts.empty?
      raise Puppet::ParseError,
        "failed to derive AMQP hosts from configuration"
    end
    amqp_hosts.map {|ip| ip + ':' + port }.join(',')
  end

  def get_amqp_vip(port)
    vip = @fuel_config[:amqp_vip]  ||  @fuel_config[:management_vip]
  end

  def get_database_vip()
    # todo: use network_roles
    @fuel_config[:database_vip]  ||  @fuel_config[:management_vip]
  end

  def get_tenant()
    return @admin_tenant_name if @admin_tenant_name
    as = @fuel_config[:access] || {:tenant=>"admin"}
    @admin_tenant_name = as[:tenant]
  end

  # classmethod
  def self.get_amqp_config(cfg)
    rv = cfg.clone()
    case cfg[:hosts].class.to_s()
      when "String"
        hosts = cfg[:hosts].split(',').map!{|x| x.split(':')}.map!{|x| [x[0], x[1] || cfg[:port].to_s]}
      when "Array"
        hosts = cfg[:hosts].map!{|x| x.split(':')}.map!{|x| [x[0], x[1] || cfg[:port].to_s]}
      else
        raise(Puppet::ParseError, "unsupported hosts field format in AMQP configure \"#{cfg[:hosts]}\".")
    end
    case cfg[:provider]
      when 'rabbitmq', 'qpid', 'qpid-rh'
        if cfg[:ha_mode]
          rv[:hosts] = hosts.map{|x| x.map!{|y| y.strip}.join(':')}.join(',')
        else
          rv[:hosts] = hosts[0][0].strip
          if hosts[0][1].strip() != cfg[:port].to_s
            rv[:port] = hosts[0][1].to_i
          end
        end
      else
        raise(Puppet::ParseError, "unsupported AMQP provider \"#{cfg[:provider]}\".")
    end
    return rv
  end

  # classmethod
  def self.get_database_url(cfg)
    #rv = cfg.clone()
    case cfg[:provider].to_s().downcase
      when "mysql"
        url_opts = {
          :read_timeout => cfg[:read_timeout],
          :charset      => cfg[:charset],
        }.select{|k,v| !v.nil? and v != ''}.collect{|k,v| "#{k}=#{v}"}
        optline = url_opts.size>0  ?  "?#{url_opts.join('&')}"  :  ''
        rv = "mysql://#{cfg[:username]}:#{cfg[:passwd]}@#{cfg[:host]}:#{cfg[:port]}/#{cfg[:database]}#{optline}"
      when "pgsql"
        raise(Puppet::ParseError, "unsupported database provider \"#{cfg[:provider]}\".")
      when "sqlite"
        dash = cfg[:database][0]=='/'  ?  ''  :  '/'
        rv = "sqlite://#{dash}#{cfg[:database]}"
      else
        raise(Puppet::ParseError, "unsupported database provider \"#{cfg[:provider]}\".")
    end
    return rv
  end

  def get_neutron_srv_api_url(srvsh)
    "#{srvsh[:api_protocol]}://#{get_neutron_srv_vip()}:#{srvsh[:bind_port]}"
  end

  # classmethod
  def self.get_keystone_auth_url(kshash)
    "#{kshash[:auth_protocol]}://#{kshash[:auth_host]}:#{kshash[:auth_port]}/#{kshash[:auth_api_version]}"
  end

  def self.get_nova_api_url(fc)
    "http://#{fc[:management_vip]}:8774/v2"
  end

  # classmethod
  def self.get_phys_bridges(l2)
    l2[:phys_nets].sort().select{|x| x[1][:bridge]&&!x[1][:bridge].empty?}.map{|x| x[1][:bridge]}
  end

  # classmethod
  def self.get_bridge_mappings(l2)
    l2[:phys_nets].sort().map{|n| "#{n[0]}:#{n[1][:bridge]}"}.join(',')
  end

  # classmethod
  def self.get_network_vlan_ranges(l2)
    l2[:phys_nets].sort().map{|n| [n[0],n[1][:vlan_range]]}.map{|n| n.delete_if{|x| x==nil||x=='nil'||x==''}}.map{|n| n.join(':')}.join(',')
  end

  def get_neutron_srv_vip()
    @fuel_config[:neutron_server_vip]  ||  @fuel_config[:management_vip]
  end

  def get_neutron_srv_ip()
    @scope.function_get_network_role_property(['management', 'ipaddr'])
  end

  def get_neutron_gre_ip() # IP, not VIP !!!
    @scope.function_get_network_role_property(['mesh', 'ipaddr']) || @scope.function_get_network_role_property(['management', 'ipaddr']) || nil
  end

  def get_amqp_passwd()
    if @fuel_config[:rabbit].nil? || @fuel_config[:rabbit].empty?
      raise(Puppet::ParseError, "AMQP password not given!!!")
    end
    @fuel_config[:rabbit][:password]
  end

  def get_nova_admin_passwd()
    if @fuel_config[:nova].nil? || @fuel_config[:nova].empty? || @fuel_config[:nova][:user_password].nil?
      raise(Puppet::ParseError, "Nova password not given!!!")
    end
    @fuel_config[:nova][:user_password]
  end

  def get_bridge_name(bb)
    #todo: Import bridge names from network-roles
    case bb
      when 'management'  then 'br-mgmt'
      when 'public'  then 'br-ex'
      when 'private' then 'br-prv'
      when 'tunnel'  then 'br-tun'
      when 'integration' then 'br-int'
    end
  end

  def get_default_routers()
    {
      :router04 => {
        :tenant => get_tenant(),
        :virtual => false,  # Virtual router should not be create
        :external_network => "net04_ext",
        :internal_networks => ["net04"],
      }
    }
  end

  def get_phys_nets(tun_mode, net_hash)
    return net_hash if net_hash
    rv = {
      :physnet1 => {
        :bridge => get_bridge_name('public'),
        :vlan_range => nil,
      }
    }
    if ! tun_mode
      rv[:physnet2] = {
        :bridge => get_bridge_name('private'),
        :vlan_range => "3000:4094",
      }
    end
    return rv
  end

  def get_predefined_networks(tun_mode, net_hash)
    return net_hash if net_hash
    net_ext = "10.100.100"
    net_int = "192.168.111"
    int_physnet = tun_mode  ?  nil  :  'physnet2'
    return {
      :net04_ext => {
        :shared => false,
        :tenant => get_tenant(),
        :L2 => {
          :router_ext   => true,
          :network_type => 'local',
          :physnet      => nil,
          :segment_id   => nil,
        },
        :L3 => {
          :subnet => "#{net_ext}.0/24",
          :gateway => "#{net_ext}.1",
          :nameservers => [],
          :enable_dhcp => false,
          :floating => "#{net_ext}.130:#{net_ext}.254",
        },
      },
      :net04 => {
        :shared => false,
        :tenant => get_tenant(),
        :L2 => {
          :router_ext   => false,
          :network_type => 'gre', # or vlan
          :physnet      => int_physnet,
          :segment_id   => nil,
        },
        :L3 => {
          :subnet => "#{net_int}.0/24",
          :gateway => "#{net_int}.1",
          :nameservers => ["8.8.4.4", "8.8.8.8"],
          :enable_dhcp => true,
          :floating => nil,
        },
      },
    }
  end


  def generate_default_neutron_config()
    # fields defined as NIL are required
    cores_count = Facter.processorcount.to_i * 5 rescue 0 # the safety is safe
    rv = {
      :amqp => {
        :provider => default_amqp_provider(),
        :username => "nova",
        :passwd => nil,
        :hosts => default_amqp_hosts(),
        :port => default_amqp_port(default_amqp_provider()),
        :ha_mode => true,
        :control_exchange => "neutron",
        :heartbeat => 60,
        :protocol => "tcp",
        :rabbit_virtual_host => "/",
      },
      :database => {
        :url => nil, # will be calculated later
        :provider => "mysql",
        :host => get_database_vip(),
        :port => 0,
        :database => "neutron",
        :username => "neutron",
        :passwd   => "neutron",
        :reconnects => -1,
        :reconnect_interval => 2,
        :read_timeout => 60,
        :charset  => nil,
        :max_pool_size => [10, [cores_count > 0 ? cores_count : 1 , 30].min].max, # 10<=max_pool_size<=30
        :max_overflow => [20, [cores_count > 0 ? cores_count : 1, 60].min].max, # 20<=max_pool_size<=60
        :idle_timeout => 3600,
      },
      :keystone => {
        :auth_region => 'RegionOne',
        :auth_url => nil, # will be calculated later
        :auth_host => get_management_vip(),
        :auth_port => 35357,
        :auth_protocol => "http",
        :auth_api_version => "v2.0",
        :admin_tenant_name => "services",
        :admin_user => "neutron",
        :admin_password => "neutron_pass",
        :admin_email => "neutron@localhost",
        :signing_dir => "/var/lib/neutron/keystone-signing",
      },
      :server => {
        :api_url => nil, # will be calculated later
        :api_protocol => "http",
        :bind_host => get_neutron_srv_ip(),
        :bind_port => 9696,
        :agent_down_time => 15,
        :report_interval => 5,
        :allow_bulk      => true,
        :api_workers     => nil,
        :rpc_workers     => nil,
        :control_exchange=> 'neutron',
        :core_plugin  => 'openvswitch',
        :service_plugins  => 'neutron.services.l3_router.l3_router_plugin.L3RouterPlugin,neutron.services.firewall.fwaas_plugin.FirewallPlugin,neutron.services.metering.metering_plugin.MeteringPlugin',
        :notify_nova_send_events_interval => 2,
        :notify_nova_on_port_status_changes => true,
        :notify_nova_on_port_data_changes => true,
        :notify_nova_api_url => nil, # will be calculated later
        :notify_nova_admin_username => 'nova',
        :notify_nova_admin_password => get_nova_admin_passwd(),
        :notify_nova_admin_auth_url => nil, # will be calculated later
      },
      :metadata => {
        :nova_metadata_ip => get_management_vip(),
        :nova_metadata_port => 8775,
        :metadata_ip => '169.254.169.254',
        :metadata_port => 8775,
        :metadata_proxy_shared_secret => "secret-word",
        :workers => nil,
        :backlog => 2048,
      },
      :L2 => {
        :provider => "ml2",
        :base_mac => "fa:16:3e:00:00:00",
        :mac_generation_retries => 32,
        :segmentation_type => "gre",
        :tunnel_id_ranges => "3000:65535",
        :phys_bridges => nil, # will be calculated later from :phys_nets
        :bridge_mappings => nil, # will be calculated later from :phys_nets
        :network_vlan_ranges => nil, # will be calculated later from :phys_nets
        :integration_bridge => get_bridge_name('integration'),
        :tunnel_bridge => get_bridge_name('tunnel'),
        :int_peer_patch_port => "patch-tun",
        :tun_peer_patch_port => "patch-int",
        :local_ip => get_neutron_gre_ip(),
        # ml2 aware parameters
        :mechanism_drivers => nil,
        :type_drivers => nil,
        :tenant_network_types => nil,
        :flat_networks => nil,
        :tunnel_types => nil,
        :vxlan_group => nil,
        :vni_ranges => nil,
      },
      :L3 => {
        :router_id => nil,
        :gateway_external_network_id => nil,
        :use_namespaces => true,
        :allow_overlapping_ips => true,
        :network_auto_schedule => true,
        :router_auto_schedule  => true,
        :public_bridge => get_bridge_name('public'),
        #:public_network => "net04_ext",
        :send_arp_for_ha => 8,
        :resync_interval => 40,
        :resync_fuzzy_delay => 5,
        :dhcp_agent => {
          :enable_isolated_metadata => false,
          :enable_metadata_network => false,
          :lease_duration => 120,
        },
      },
      :predefined_routers => get_default_routers(),
      :root_helper => "sudo neutron-rootwrap /etc/neutron/rootwrap.conf",
      :polling_interval => 2,
    }
    rv[:database][:port] = case rv[:database][:provider].upcase.to_sym
      when :MYSQL then 3306
      when :PGSQL then 5432
      when :SQLITE then nil
      else
        raise(Puppet::ParseError, "Unknown database provider '#{rv[:database][:provider]}'")
    end
    return rv
  end

  def self.get_ml2_plugin_config(l2)
    rv = Marshal.load(Marshal.dump(l2))
    rv[:mechanism_drivers] ||= 'openvswitch'
    rv[:type_drivers] ||= "#{l2[:segmentation_type]},flat,local"
    rv[:tenant_network_types] ||= "#{l2[:segmentation_type]},flat,local"
    rv[:flat_networks] ||= '*'
    if l2[:enable_tunneling]
      rv[:tunnel_types] ||= l2[:segmentation_type]
      rv[:tunnel_id_ranges] = l2[:tunnel_id_ranges]
      rv[:vxlan_group] ||= 'None'   # because OVS don't support MCAST VxLAN implementation,
      rv[:vni_ranges] ||= l2[:tunnel_id_ranges]
    else
      rv[:tunnel_types] = ''
      rv[:tunnel_id_ranges] = ''
      rv[:vxlan_group] = 'None'
      rv[:vni_ranges] = ''
    end
    return rv
  end

  def initialize(scope, cfg, section_name)
    @scope = scope
    @fuel_config = cfg
    @neutron_config_from_nailgun = cfg[section_name.to_sym()]
    @admin_tenant_name = nil
    #Puppet::debug(@fuel_config.to_yaml)
  end

  def generate_config()
    @neutron_config = _generate_config(generate_default_neutron_config(), @neutron_config_from_nailgun, [])
    # prevent getters, like @neutron_config_from_nailgun[:L2][:XXX] from errors
    @neutron_config_from_nailgun[:L2] ||= {}
    @neutron_config_from_nailgun[:L3] ||= {}
    # calculate some sections if not given
    @neutron_config[:database][:url] ||= MrntNeutron.get_database_url(@neutron_config[:database])
    @neutron_config[:keystone][:auth_url] ||= MrntNeutron.get_keystone_auth_url(@neutron_config[:keystone])
    @neutron_config[:server][:notify_nova_admin_auth_url] = @neutron_config[:keystone][:auth_url]

    @neutron_config[:server][:api_url] ||= get_neutron_srv_api_url(@neutron_config[:server])
    @neutron_config[:server][:notify_nova_api_url] ||= MrntNeutron.get_nova_api_url(@fuel_config)

    @neutron_config[:amqp] ||= MrntNeutron.get_amqp_config(@neutron_config[:amqp])
    # calculate tunneling value from segm.type
    if [:gre, :vxlan, :lisp].include? @neutron_config[:L2][:segmentation_type].downcase.to_sym
      @neutron_config[:L2][:enable_tunneling] = true
    else
      @neutron_config[:L2][:enable_tunneling] = false
      @neutron_config[:L2][:tunnel_id_ranges] = nil
    end
    # get amqp password from main config if for Neutron not given.
    if @neutron_config[:amqp][:passwd].nil?
      @neutron_config[:amqp][:passwd] = get_amqp_passwd()
    end
    @neutron_config[:predefined_networks] = get_predefined_networks(
      @neutron_config[:L2][:enable_tunneling],
      @neutron_config_from_nailgun[:predefined_networks]
    )
    @neutron_config[:L2][:phys_nets] = get_phys_nets(
      @neutron_config[:L2][:enable_tunneling],
      @neutron_config_from_nailgun[:L2][:phys_nets]
    )
    @neutron_config[:L2][:network_vlan_ranges] = MrntNeutron.get_network_vlan_ranges(@neutron_config[:L2])
    @neutron_config[:L2][:bridge_mappings] = MrntNeutron.get_bridge_mappings(@neutron_config[:L2])
    @neutron_config[:L2][:phys_bridges] = MrntNeutron.get_phys_bridges(@neutron_config[:L2])
    if @neutron_config[:L2][:provider].downcase.to_sym == :ovs
      #todo (sv): rename to shot form 'ovs', after https://bugs.launchpad.net/neutron/+bug/1286052
      @neutron_config[:server][:core_plugin] = 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2'
    elsif @neutron_config[:L2][:provider].downcase.to_sym == :nsx
      @neutron_config[:server][:core_plugin] = 'neutron.plugins.vmware.plugin.NsxPlugin'
      #@neutron_config[:server][:service_plugins] = ' '
      # NSX plugin doesn't deploy properly if service_plugins is empty,
      # it should be undefined, but we can't undefine it here,
      # so we ensure that it is absent in plugin_neutronnsx/manifests/alter_neutron_server.pp

    else
      #todo (sv): rename to shot form 'ml2', after https://bugs.launchpad.net/neutron/+bug/1286052
      @neutron_config[:server][:core_plugin] = 'neutron.plugins.ml2.plugin.Ml2Plugin'
      @neutron_config[:L2][:provider] = 'ml2'
      @neutron_config[:L2] = MrntNeutron.get_ml2_plugin_config(@neutron_config[:L2])
    end
    return @neutron_config
  end

  private

  def _generate_config(cfg_dflt, cfg_user, path)
    if cfg_user.nil? or cfg_user.empty?
      return Marshal.load(Marshal.dump(cfg_dflt))
    end
    rv = {}
    cfg_dflt.each() do |k, v|
      # if v == nil && cfg_user[k] == nil
      #   raise(Puppet::ParseError, "Missing required field '#{path}.#{k}'.")
      # end
      if (v != nil && cfg_user[k] != nil && v.class() != cfg_user[k].class() \
          && ! (!!v == v && !!cfg_user[k] == cfg_user[k]))
        raise(Puppet::ParseError, "Invalid format of config hash (field=\"#{k}\").")
      end
      rv[k] = case v.class.to_s
        when "Hash"     then cfg_user[k] ? _generate_config(v,cfg_user[k], path.clone.insert(-1, k)) : v
        when "Array"    then cfg_user[k]&&cfg_user[k].empty?() ? v : cfg_user[k]
        when "String"   then cfg_user[k] ? cfg_user[k] : v
        when "Fixnum"   then cfg_user[k] ? cfg_user[k] : v
        when "NilClass" then cfg_user[k] ? cfg_user[k] : v
        else v
      end
    end
    return rv
  end
end


Puppet::Parser::Functions::newfunction(:sanitize_neutron_config, :type => :rvalue, :doc => <<-EOS
    This function get Hash of Neutron configuration
    and sanitize it.

    Example call this:
    $config = sanitize_neutron_config($::fuel_settings, 'neutron_settings')

    EOS
  ) do |argv|
  Puppet::Parser::Functions.autoloader.loadall
  given_config = MrntNeutron.sanitize_hash(argv[0])
  q_conf = MrntNeutron.new(self, given_config, argv[1])
  rv = q_conf.generate_config()
  # pUPPET not allow hashes with SYM keys. normalize keys
  rv = JSON.load(rv.to_json)
  Puppet::debug("-*- Actual Neutron config is: #{rv.to_yaml()}")
  return rv
end

# vim: set ts=2 sw=2 et :
