require 'ipaddr'
require 'yaml'
require 'forwardable'
require 'puppet/parser'
require 'puppet/parser/templatewrapper'
require 'puppet/resource/type_collection_helper'
require 'puppet/util/methodhelper'
require 'puppetx/l23_utils'
require 'puppetx/l23_network_scheme'



module L23network
  def self.default_offload_set
    {
      'generic-receive-offload'      => false,
      'generic-segmentation-offload' => false
    }
  end

  def self.correct_ethtool_set(prop_hash)
    if !prop_hash.has_key?('ethtool') and (prop_hash.has_key?('vendor_specific') and prop_hash['vendor_specific']['disable_offloading'])
      # add default offload settings if:
      #  * no ethtool properties given
      #  * "disable offload" flag given
      rv = {}.merge prop_hash
      rv['ethtool'] ||= {}
      rv['ethtool']['offload'] = default_offload_set()
      rv['vendor_specific'].delete('disable_offloading')
    else
      rv = prop_hash
    end
    return rv
  end

  def self.sanitize_transformation(trans, def_provider=nil)
    action = trans[:action].to_s.downcase()
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
        :provider             => def_provider
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
        :provider             => def_provider
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
        :provider             => def_provider
      }
      when "add-patch" then {
        :name            => "unnamed", # calculated later
        :bridges         => [],
        :mtu             => nil,
        :vendor_specific => nil,
        :provider        => def_provider
      }
      else
        raise(Puppet::ParseError, "Unknown transformation: '#{action}'.")
    end
    # replace defaults to real parameters
    rv.map{|k,v| rv[k] = trans[k] if trans.has_key? k }
    # Validate and mahgle highly required properties. Most of properties should be validated in puppet type.
    rv[:action] = action
    if not rv[:name].is_a? String
      raise(Puppet::ParseError, "Unnamed transformation: '#{action}'.")
    end
    if action == "add-patch"
      if !rv[:bridges].is_a? Array  or  rv[:bridges].size() != 2
        raise(Puppet::ParseError, "Transformation patch have wrong 'bridges' parameter.")
      end
      rv[:name] = get_patch_name(rv[:bridges])  # name for patch SHOULD be auto-generated
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
    debug("generate_network_config(): collect interfaces")
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
          if v.to_s != ''
            k = k.to_s.tr('-','_').to_sym
            ports_properties[int_name][k] = v
          end
        end
      end
    end
    # collect L3::ifconfig properties from 'endpoints' section
    debug("generate_network_config(): collect endpoints")
    endpoints = {}
    if config_hash[:endpoints].is_a? Hash and !config_hash[:endpoints].empty?
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
    else
      config_hash[:endpoints] = {}
    end

    # pre-check and auto-add main interface for sub-interface
    # to transformation if required
    debug("generate_network_config(): precheck transformations")
    tmp = []
    config_hash[:transformations].each do |t|
      if (t[:action].match(/add-(port|bond)/) && t[:name].match(/\.\d+$/))
        # we found vlan subinterface, but main interface for one didn't defined
        # earlier. We should configure main interface as unaddressed interface
        # wich has state UP to prevent fails in network configuration
        name = t[:name].split('.')[0]
        if tmp.select{|x| x[:action].match(/add-(port|bond)/) && x[:name]==name}.empty?
          debug("Auto-add 'add-port(#{name})' for '#{t[:name]}'")
          tmp << {
            :action => 'add-port',
            :name   => name
          }
        end
        tmp << t
      elsif (i=tmp.index{|x| x[:action].match(/add-(port|bond)/) && x[:name]==t[:name]})
        # we has transformation for this interface already auto-added by previous
        # condition. We should merge this properties into which are autocreated
        # earlier by transformation and forget this.
        #
        # It's looks like some strange reordering
        tmp[i].merge! t
        debug("Auto-add 'move-properties-for-port(#{t[:name]})', because one autocreated early.")
      else
        tmp << t
      end
    end
    config_hash[:transformations] = tmp
    debug("generate_network_config(): process transformations")
    # execute transformations
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

      #debug("TXX: '#{t[:name]}' =>  '#{t.to_yaml.gsub('!ruby/sym ',':')}'.")
      trans = L23network.sanitize_transformation(t, default_provider)
      #debug("TTT: '#{trans[:name]}' =>  '#{trans.to_yaml.gsub('!ruby/sym ',':')}'.")

      if !ports_properties[trans[:name].to_sym()].nil?
        trans.merge! ports_properties[trans[:name].to_sym()]
      end

      # create puppet resources for transformations
      resource = res_factory[action]
      resource_properties = { }
      debug("generate_network_config(): Transformation '#{trans[:name]}' will be produced as \n#{trans.to_yaml.gsub('!ruby/sym ',':')}")

      trans.select{|k,v| k != :action}.each do |k,v|
        if ['Hash', 'Array'].include? v.class.to_s
          resource_properties[k.to_s] = L23network.reccursive_sanitize_hash(v)
          if action == :bond && k==:interface_properties
            # search 'disable_offloading' flag and correct ethtool properties if required
            resource_properties[k.to_s] = L23network.correct_ethtool_set(resource_properties[k.to_s])
          end
        elsif ! v.nil?
          resource_properties[k.to_s] = v
        else
          #todo(sv): more powerfull handler for 'nil' properties
        end
      end

      resource_properties['require'] = [previous] if previous
      resource_properties = L23network.correct_ethtool_set(resource_properties)
      function_create_resources([resource, {
        "#{trans[:name]}" => resource_properties
      }])
      transformation_success << "#{t[:action].strip()}(#{trans[:name]})"
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

    # create resources for endpoints
    # in order, defined by transformation
    debug("generate_network_config(): process endpoints")
    create_routes=[]
    full_ifconfig_order.each do |endpoint_name|
      if endpoints[endpoint_name]
        resource_properties = { }

        # create resource
        resource = res_factory[:ifconfig]
        debug("generate_network_config(): Endpoint '#{endpoint_name}' will be created with additional properties \n#{endpoints[endpoint_name].to_yaml.gsub('!ruby/sym ',':')}")
        # collect properties for creating endpoint resource
        endpoints[endpoint_name].each_pair do |k,v|
          if k.to_s.downcase == 'routes'
            # for routes we should create additional resource, not a property of ifconfig
            next if ! v.is_a?(Array)
            v.each do |vv|
              create_routes << vv
            end
          elsif ['Hash', 'Array'].include? v.class.to_s
            resource_properties[k.to_s] = L23network.reccursive_sanitize_hash(v)
          elsif ! v.nil?
            resource_properties[k.to_s] = v
          else
            #todo(sv): more powerfull handler for 'nil' properties
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
        resource_properties = L23network.correct_ethtool_set(resource_properties)
        function_create_resources([resource, {
          "#{endpoint_name}" => resource_properties
        }])
        transformation_success <<  "endpoint(#{endpoint_name})"
        previous = "#{resource}[#{endpoint_name}]"
      end
    end

    debug("generate_network_config(): process additional routes")
    create_routes.each do |route|
      next if !route.has_key?(:net) or !route.has_key?(:via)
      route_properties = {
        'destination' => route[:net],
        'gateway'     => route[:via]
      }
      route_properties[:metric] = route[:metric] if route[:metric].to_i > 0
      route_name = L23network.get_route_resource_name(route[:net], route[:metric])
      function_create_resources(['l23network::l3::route', {
          "#{route_name}" => route_properties
      }])
      transformation_success <<  "route_for(#{route[:net]})"
    end

    debug("generate_network_config(): done...")
    return transformation_success.join(" -> ")
end
# vim: set ts=2 sw=2 et :
