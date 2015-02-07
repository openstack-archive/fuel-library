require 'ipaddr'
require 'forwardable'
require 'puppet/parser'
require 'puppet/parser/templatewrapper'
require 'puppet/resource/type_collection_helper'
require 'puppet/util/methodhelper'
require 'puppetx/l23_utils'

begin
  require 'puppet/parser/functions/lib/l23network_scheme.rb'
rescue LoadError => e
  # puppet apply does not add module lib directories to the $LOAD_PATH (See
  # #4248). It should (in the future) but for the time being we need to be
  # defensive which is what this rescue block is doing.
  rb_file = File.join(File.dirname(__FILE__),'lib','l23network_scheme.rb')
  load rb_file if File.exists?(rb_file) or raise e
end



module L23network
  def self.sanitize_transformation(trans, def_provider)
    action = trans[:action].downcase()
    # Setup defaults
    rv = case action
      when "noop" then {
        :name     => nil,
        :provider => nil
      }
      when "add-br" then {
        :name                 => nil,
        :stp                  => nil,
        :bpdu_forward         => nil,
#       :bridge_id            => nil,
        :external_ids         => nil,
#       :interface_properties => nil,
        :vendor_specific      => nil,
        :provider             => nil
      }
      when "add-port" then {
        :name                 => nil,
        :bridge               => nil,
#       :type                 => "internal",
        :mtu                  => nil,
        :ethtool              => nil,
        :vlan_id              => nil,
        :vlan_dev             => nil,
#       :trunks               => [],
        :vendor_specific      => nil,
        :provider             => nil
      }
      when "add-bond" then {
        :name                 => nil,
        :bridge               => nil,
        :mtu                  => nil,
        :interfaces           => [],
#       :vlan_id              => 0,
#       :trunks               => [],
        :bond_properties      => nil,
        :interface_properties => nil,
        :vendor_specific      => nil,
        :provider             => nil
      }
      when "add-patch" then {
        :name            => "unnamed", # calculated later
        :peers           => [nil, nil],
        :bridges         => [],
        :vlan_ids        => [0, 0],
#       :trunks          => [],
        :vendor_specific => nil,
        :provider        => nil
      }
      else
        raise(Puppet::ParseError, "Unknown transformation: '#{action}'.")
    end
    # replace defaults to real parameters
    rv[:action] = action
    rv.each do |k,v|
      if trans[k]
        rv[k] = trans[k]
      end
    end
    rv[:provider] = def_provider if rv[:provider].nil?
    # Check for incorrect parameters
    if not rv[:name].is_a? String
      raise(Puppet::ParseError, "Unnamed transformation: '#{action}'.")
    end
    name = rv[:name]
    if not rv[:bridge].is_a? String and !["add-patch", "add-br"].index(action)
      raise(Puppet::ParseError, "Undefined bridge for transformation '#{action}' with name '#{name}'.")
    end
    if action == "add-patch"
      if not rv[:bridges].is_a? Array  and  rv[:bridges].size() != 2
        raise(Puppet::ParseError, "Transformation patch have wrong 'bridges' parameter.")
      end
      name = "patch__#{rv[:bridges][0]}__#{rv[:bridges][1]}"
      if not rv[:peers].is_a? Array  and  rv[:peers].size() != 2
        raise(Puppet::ParseError, "Transformation patch '#{name}' have wrong 'peers' parameter.")
      end
      rv[:name] = name
    end
    if action == "add-bond"
      if not (rv[:interfaces].is_a?(Array) and rv[:interfaces].size() >= 2)
        raise(Puppet::ParseError, "Transformation bond '#{name}' have wrong 'interfaces' parameter.")
      end
    end
    return rv
  end
end

Puppet::Parser::Functions::newfunction(:generate_network_config, :type => :rvalue, :doc => <<-EOS
    This function get Hash of network interfaces and endpoints configuration
    and realized it.

    EOS
  ) do |argv|

    def default_netmask()
      "/24"
    end

    def create_endpoint()
      {
        :ipaddr => []
      }
    end

    def res_factory()
      # define internal puppet parameters for creating resources
      {
        :br       => 'l23network::l2::bridge',
        :port     => 'l23network::l2::port',
        :bond     => 'l23network::l2::bond',
        :patch    => 'l23network::l2::patch',
        :ifconfig => 'l23network::l3::ifconfig'
      }
    end

    if argv.size != 0
      raise(Puppet::ParseError, "generate_network_config(): Wrong number of arguments.")
    end
    config_hash = L23network::Scheme.get_config(lookupvar('l3_fqdn_hostname'))
    if config_hash.nil?
      raise(Puppet::ParseError, "generate_network_config(...): You must call prepare_network_config(...) first!")
    end

    # we can't imagine, that user can write in this field, but we try to convert to numeric and compare
    if config_hash[:version].to_s.to_f < 1.1
      raise(Puppet::ParseError, "generate_network_config(...): You network_scheme hash has wrong format.\nThis parser can work with v1.1 format, please convert you config.")
    end

    default_provider = config_hash[:provider] || 'lnx'

    # collect interfaces and endpoints
    ifconfig_order = []
    born_ports = []
    # collect L2::port properties from 'interfaces' section
    ports_properties = {}  # additional parameters from interfaces was stored here
    config_hash[:interfaces].each do |int_name, int_properties|
      int_name = int_name.to_sym()
      #endpoints[int_name] = create_endpoint()
      born_ports << int_name
      # add some of 1st level interface properties to it's config
      ports_properties[int_name] ||= {}
      if ! int_properties.nil?
        int_properties.each do |k,v|
          k = k.to_s.tr('-','_').to_sym
          ports_properties[int_name][k] = v
        end
      end
    end
    # collect L3::ifconfig properties from 'endpoints' section
    endpoints = {}
    config_hash[:endpoints].each do |e_name, e_properties|
      e_name = e_name.to_sym()
      endpoints[e_name] = create_endpoint()
      if ! (e_properties.nil? or e_properties.empty?)
        e_properties.each do |k,v|
          k = k.to_s.tr('-','_').to_sym
          if k == :IP
            if !(v.is_a?(Array) || ['none','dhcp',nil].include?(v))
              raise(Puppet::ParseError, "generate_network_config(): IP field for endpoint '#{e_name}' must be array of IP addresses, 'dhcp' or 'none'.")
            elsif ['none','dhcp',''].include?(v.to_s)
              # 'none' and 'dhcp' should be passed to resource not as list
              endpoints[e_name][:ipaddr] = (v.to_s == 'dhcp'  ?  'dhcp'  :  'none')
            else
              v.each do |ip|
                begin
                  iip = IPAddr.new(ip)  # validate IP address
                  endpoints[e_name][:ipaddr] ||= []
                  endpoints[e_name][:ipaddr] << ip
                rescue
                  raise(Puppet::ParseError, "generate_network_config(): IP address '#{ip}' for endpoint '#{e_name}' wrong!.")
                end
              end
            end
          else
            endpoints[e_name][k] = v
          end
        end
      else
        endpoints[e_name][:ipaddr] = 'none'
      end
    end

    # execute transformations
    # todo: if provider="lnx" execute transformations for LNX bridges
    transformation_success = []
    previous = nil
    config_hash[:transformations].each do |t|
      action = t[:action].strip()
      if action.start_with?('add-')
        action = t[:action][4..-1].to_sym()
        action_ensure = nil
      elsif action.start_with?('del-')
        action = t[:action][4..-1].to_sym()
        action_ensure = 'absent'
      else
        action = t[:action].to_sym()
      end

      # add newly-created interface to ifconfig order
      if [:noop, :port, :br].index(action)
        if ! ifconfig_order.include? t[:name].to_sym()
          ifconfig_order << t[:name].to_sym()
        end
      end

      next if action == :noop

      trans = L23network.sanitize_transformation(t, default_provider)
      if !ports_properties[trans[:name].to_sym()].nil?
        trans.merge! ports_properties[trans[:name].to_sym()]
      end

      # create puppet resources for transformations
      resource = res_factory[action]
      resource_properties = { }
      debug("generate_network_config(): Transformation '#{trans[:name]} will be produced as '#{trans}'.")

      trans.select{|k,v| k != :action}.each do |k,v|
        if ['Hash', 'Array'].include? v.class.to_s
          resource_properties[k.to_s] = L23network.reccursive_sanitize_hash(v)
        elsif ! v.nil?
          resource_properties[k.to_s] = v
        else
          #pass
        end
      end

      resource_properties['require'] = [previous] if previous
      function_create_resources([resource, {
        "#{trans[:name]}" => resource_properties
      }])
      transformation_success.insert(-1, "#{t[:action].strip()}(#{trans[:name]})")
      born_ports.insert(-1, trans[:name].to_sym()) if action != :patch
      previous = "#{resource}[#{trans[:name]}]"
    end

    # check for all in endpoints are in interfaces or born by transformation
    config_hash[:endpoints].each do |e_name, e_properties|
      if not born_ports.index(e_name.to_sym())
        raise(Puppet::ParseError, "generate_network_config(): Endpoint '#{e_name}' not found in interfaces or transformations result.")
      end
    end

    # Calculate delta between all endpoints and ifconfig_order
    ifc_delta = endpoints.keys().sort() - ifconfig_order
    full_ifconfig_order = ifconfig_order + ifc_delta

    # create resources for interfaces and endpoints
    # in order, defined by transformation
    full_ifconfig_order.each do |endpoint_name|
      if endpoints[endpoint_name]
        resource_properties = { }

        # create resource
        resource = res_factory[:ifconfig]
        debug("generate_network_config(): Endpoint '#{endpoint_name}' will be created with additional properties '#{endpoints[endpoint_name]}'.")
        # collect properties for creating endpoint resource
        endpoints[endpoint_name].each_pair do |k,v|
          if ['Hash', 'Array'].include? v.class.to_s
            resource_properties[k.to_s] = L23network.reccursive_sanitize_hash(v)
          elsif ! v.nil?
            resource_properties[k.to_s] = v
          else
            #pass
          end
        end
        resource_properties['require'] = [previous] if previous
        # # set ipaddresses
        # #if endpoints[endpoint_name][:IP].empty?
        # #  p_resource.set_parameter(:ipaddr, 'none')
        # #elsif ['none','dhcp'].index(endpoints[endpoint_name][:IP][0])
        # #  p_resource.set_parameter(:ipaddr, endpoints[endpoint_name][:IP][0])
        # #else
        #   # ipaddrs = []
        #   # endpoints[endpoint_name][:IP].each do |i|
        #   #   if i =~ /\/\d+$/
        #   #     ipaddrs.insert(-1, i)
        #   #   else
        #   #     ipaddrs.insert(-1, "#{i}#{default_netmask()}")
        #   #   end
        #   # end
        #   # p_resource.set_parameter(:ipaddr, ipaddrs)
        # #end
        # #set another (see L23network::l3::ifconfig DOC) parametres
        function_create_resources([resource, {
          "#{endpoint_name}" => resource_properties
        }])
        transformation_success.insert(-1, "endpoint(#{endpoint_name})")
        previous = "#{resource}[#{endpoint_name}]"
      end
    end

    return transformation_success.join(" -> ")
end
# vim: set ts=2 sw=2 et :