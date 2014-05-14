require 'ipaddr'
require 'forwardable'
require 'puppet/parser'
require 'puppet/parser/templatewrapper'
require 'puppet/resource/type_collection_helper'
require 'puppet/util/methodhelper'

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
  def self.sanitize_transformation(trans)
    action = trans[:action].downcase()
    # Setup defaults
    rv = case action
      when "noop" then {
        :name => nil,
      }
      when "add-br" then {
        :name => nil,
        #:stp_enable => true,
        :skip_existing => true
      }
      when "add-port" then {
        :name => nil,
        :bridge => nil,
        #:type => "internal",
        :tag => 0,
        :trunks => [],
        :port_properties => [],
        :interface_properties => [],
        :skip_existing => true
      }
      when "add-bond" then {
        :name => nil,
        :provider => 'ovs',
        :bridge => nil,
        :interfaces => [],
        :tag => 0,
        :trunks => [],
        :properties => [],
        #:port_properties => [],
        #:interface_properties => [],
        :skip_existing => true
      }
      when "add-patch" then {
        :name => "unnamed", # calculated later
        :peers => [nil, nil],
        :bridges => [],
        :tags => [0, 0],
        :trunks => [],
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
        :properties => {},
        :IP => []
      }
    end

    if argv.size != 0
      raise(Puppet::ParseError, "generate_network_config(): Wrong number of arguments.")
    end

    config_hash = L23network::Scheme.get_config(lookupvar('l3_fqdn_hostname'))
    if config_hash.nil?
      raise(Puppet::ParseError, "get_network_role_property(...): You must call prepare_network_config(...) first!")
    end

    # define internal puppet parameters for creating resources
    res_factory = {
      :br       => { :name_of_resource => 'l23network::l2::bridge' },
      :port     => { :name_of_resource => 'l23network::l2::port' },
      :bond     => { :name_of_resource => 'l23network::l2::bond' },
      :bond_lnx => { :name_of_resource => 'l23network::l3::ifconfig' },
      :patch    => { :name_of_resource => 'l23network::l2::patch' },
      :ifconfig => { :name_of_resource => 'l23network::l3::ifconfig' }
    }
    res_factory.each do |k, v|
      if v[:name_of_resource].index('::')
        # operate by Define
        res_factory[k][:resource] = lookuptype(v[:name_of_resource].downcase())  # may be find_definition(k.downcase())
        res_factory[k][:type_of_resource] = :define
      else
        # operate by custom Type
        res_factory[k][:resource] = Puppet::Type.type(v[:name_of_resource].to_sym())
        res_factory[k][:type_of_resource] = :type
      end
    end

    # collect interfaces and endpoints
    endpoints = {}
    ifconfig_order = []
    born_ports = []
    config_hash[:interfaces].each do |int_name, int_properties|
      int_name = int_name.to_sym()
      endpoints[int_name] = create_endpoint()
      born_ports.insert(-1, int_name)
      # add some of 1st level interface properties to it's config
      int_properties.each do |k,v|
        next if ! ['macaddr', 'mtu', 'ethtool'].index(k.to_s)
        endpoints[int_name][:properties][k.to_sym] = v
      end
    end
    config_hash[:endpoints].each do |e_name, e_properties|
      e_name = e_name.to_sym()
      if not endpoints[e_name]
        endpoints[e_name] = create_endpoint()
      end
      e_properties.each do |k,v|
        if k.to_sym() == :IP
          if !(v.is_a?(Array) || ['none','dhcp',nil].include?(v))
            raise(Puppet::ParseError, "generate_network_config(): IP field for endpoint '#{e_name}' must be array of IP addresses, 'dhcp' or 'none'.")
          elsif ['none','dhcp',nil].include?(v)
            endpoints[e_name][:IP].insert(-1, v ? v : 'none')
          else
            v.each do |ip|
              begin
                iip = IPAddr.new(ip)
                endpoints[e_name][:IP].insert(-1, ip)
              rescue
                raise(Puppet::ParseError, "generate_network_config(): IP address '#{ip}' for endpoint '#{e_name}' wrong!.")
              end
            end
          end
        else
          endpoints[e_name][:properties][k.to_sym()] = v
        end
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
      else
        action = t[:action].to_sym()
      end

      # add newly-created interface to ifconfig order
      if [:noop, :port, :br].index(action)
        if ! ifconfig_order.index(t[:name].to_sym())
          ifconfig_order.insert(-1, t[:name].to_sym())
        end
      elsif action == :bond
        t[:provider] = 'ovs' if ! t[:provider]  # default provider for Bond
        if ! t[:interfaces].is_a? Array
          raise(Puppet::ParseError, "generate_network_config(): 'add-bond' resource should has non-empty 'interfaces' list.")
        end
        if t[:provider] == 'lnx'
          if ! t[:properties].is_a? Hash
            raise(Puppet::ParseError, "generate_network_config(): 'add-bond' resource should has 'properties' hash for '#{t[:provider]}' provider.")
          else
            if t[:properties].size < 1
              raise(Puppet::ParseError, "generate_network_config(): 'add-bond' resource should has non-empty 'properties' hash for '#{t[:provider]}' provider.")
            end
          end
        elsif t[:provider] == 'ovs'
          if ! t[:properties].is_a? Array
            raise(Puppet::ParseError, "generate_network_config(): 'add-bond' resource should has 'properties' array for '#{t[:provider]}' provider.")
          else
            if t[:properties].size < 1
              raise(Puppet::ParseError, "generate_network_config(): 'add-bond' resource should has non-empty 'properties' array for '#{t[:provider]}' provider.")
            end
          end
        else
          raise(Puppet::ParseError, "generate_network_config(): 'add-bond' resource has wrong provider '#{t[:provider]}'.")
        end
        if t[:provider] == 'lnx'
          if ! ifconfig_order.index(t[:name].to_sym())
            ifconfig_order.insert(-1, t[:name].to_sym())
          end
        end
        t[:interfaces].each do |physint|
          if ! ifconfig_order.index(physint.to_sym())
            ifconfig_order.insert(-1, physint.to_sym())
          end
        end
      end

      next if action == :noop

      trans = L23network.sanitize_transformation(t)

      # create puppet resources
      if action == :bond and t[:provider] == 'lnx'
        # Add Linux_bond-specific parameters to the ifconfig
        res_name = :bond_lnx
        e_name = t[:name].to_sym
        if ! endpoints[e_name]
          endpoints[e_name] = create_endpoint()
        end
        endpoints[e_name][:properties] ||= { :ipaddr => 'none' }
        endpoints[e_name][:properties][:bond_properties] = Hash[t[:properties].map{|k,v| [k.to_s,v]}]
        born_ports.insert(-1, e_name)
        t[:interfaces].each{ |iface|
          if ! endpoints[iface.to_sym]
            endpoints[iface.to_sym] = create_endpoint()
          end
          endpoints[iface.to_sym][:properties] ||= { :ipaddr => 'none' }
          endpoints[iface.to_sym][:properties][:bond_master] = t[:name].to_s
        }
        # add port to the ovs bridge as ordinary port
        tt = Marshal.load(Marshal.dump(t))
        tt[:action] = 'add-port'  # because lnx-bind is a ordinary port in OVS
        port_trans = L23network.sanitize_transformation(tt)
        resource = res_factory[:port][:resource]
        p_resource = Puppet::Parser::Resource.new(
            res_factory[:port][:name_of_resource],
            port_trans[:name],
            :scope => self,
            :source => resource
        )
        trans.select{|k,v| ! [:action, :interfaces, :properties].index(k) }.each do |k,v|
          p_resource.set_parameter(k,v)
        end
        req_list = []
        req_list.insert(-1, previous) if previous
        req_list.insert(-1, "L3_if_downup[#{tt[:name]}]")
        p_resource.set_parameter(:require, req_list)
        resource.instantiate_resource(self, p_resource)
        compiler.add_resource(self, p_resource)
        transformation_success.insert(-1, "bond-lnx_as_port(#{port_trans[:name]})")
        born_ports.insert(-1, port_trans[:name].to_sym())
      else
        # normal OVS transformation
        resource = res_factory[action][:resource]
        p_resource = Puppet::Parser::Resource.new(
            res_factory[action][:name_of_resource],
            trans[:name],
            :scope => self,
            :source => resource
        )

        # setup trunks and vlan_splinters for phys.NIC
        if (action == :port) and config_hash[:interfaces][trans[:name].to_sym] and  # does adding phys.interface?
           config_hash[:interfaces][trans[:name].to_sym][:L2] and                   # does this interface have L2 section
           config_hash[:interfaces][trans[:name].to_sym][:L2][:trunks] and          # does this interface have TRUNKS section
           config_hash[:interfaces][trans[:name].to_sym][:L2][:trunks].is_a?(Array) and
           config_hash[:interfaces][trans[:name].to_sym][:L2][:trunks].size() > 0   # does trunks section non empty?
              Puppet.debug("Configure trunks and vlan_splinters for #{trans[:name]} (value is '#{config_hash[:interfaces][trans[:name].to_sym][:L2][:vlan_splinters]}')")
              _do_trunks = true
              if config_hash[:interfaces][trans[:name].to_sym][:L2][:vlan_splinters]
                if config_hash[:interfaces][trans[:name].to_sym][:L2][:vlan_splinters] == 'on'
                  trans[:vlan_splinters] = true
                elsif config_hash[:interfaces][trans[:name].to_sym][:L2][:vlan_splinters] == 'auto'
                  sp_nics = lookupvar('l2_ovs_vlan_splinters_need_for')
                  Puppet.debug("l2_ovs_vlan_splinters_need_for: #{sp_nics}")
                  if sp_nics and sp_nics != :undefined and sp_nics.split(',').index(trans[:name].to_s)
                    Puppet.debug("enable vlan_splinters for: #{trans[:name].to_s}")
                    trans[:vlan_splinters] = true
                  else
                    trans[:vlan_splinters] = false
                    if trans[:trunks] and trans[:trunks].size() >0
                      Puppet.debug("disable vlan_splinters for: #{trans[:name].to_s}. Trunks will be set to '#{trans[:trunks].join(',')}'")
                      config_hash[:interfaces][trans[:name].to_sym][:L2][:trunks] = []
                    else
                      Puppet.debug("disable vlan_splinters for: #{trans[:name].to_s}. Trunks for this interface also disabled.")
                      _do_trunks = false
                    end
                  end
                else
                  trans[:vlan_splinters] = false
                end
              else
                trans[:vlan_splinters] = false
              end
              # add trunks list to the interface if it given
              if _do_trunks
                _trunks = [0] + trans[:trunks] + config_hash[:interfaces][trans[:name].to_sym][:L2][:trunks]  # zero for pass untagged traffic
                _trunks.sort!().uniq!()
                trans[:trunks] = _trunks
              end
              Puppet.debug("Configure trunks and vlan_splinters for #{trans[:name]} done.")
        end

        trans.select{|k,v| k != :action}.each do |k,v|
          p_resource.set_parameter(k,v)
        end

        p_resource.set_parameter(:require, [previous]) if previous
        resource.instantiate_resource(self, p_resource)
        compiler.add_resource(self, p_resource)
        transformation_success.insert(-1, "#{t[:action].strip()}(#{trans[:name]})")
        born_ports.insert(-1, trans[:name].to_sym()) if action != :patch
        previous = p_resource.to_s
      end
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

    # execute interfaces and endpoints
    # in order, defined by transformation
    full_ifconfig_order.each do |endpoint_name|
      if endpoints[endpoint_name]
        endpoint_body = endpoints[endpoint_name]
        # create resource
        resource = res_factory[:ifconfig][:resource]
        p_resource = Puppet::Parser::Resource.new(
            res_factory[:ifconfig][:name_of_resource],
            endpoint_name,
            :scope => self,
            :source => resource
        )
        p_resource.set_parameter(:interface, endpoint_name)
        # set ipaddresses
        if endpoint_body[:IP].empty?
          p_resource.set_parameter(:ipaddr, 'none')
        elsif ['none','dhcp'].index(endpoint_body[:IP][0])
          p_resource.set_parameter(:ipaddr, endpoint_body[:IP][0])
        else
          ipaddrs = []
          endpoint_body[:IP].each do |i|
            if i =~ /\/\d+$/
              ipaddrs.insert(-1, i)
            else
              ipaddrs.insert(-1, "#{i}#{default_netmask()}")
            end
          end
          p_resource.set_parameter(:ipaddr, ipaddrs)
        end
        #set another (see L23network::l3::ifconfig DOC) parametres
        endpoint_body[:properties].each do |k,v|
          p_resource.set_parameter(k,v)
        end
        p_resource.set_parameter(:require, [previous]) if previous
        resource.instantiate_resource(self, p_resource)
        compiler.add_resource(self, p_resource)
        transformation_success.insert(-1, "endpoint(#{endpoint_name})")
        previous = p_resource.to_s
      end
    end

    return transformation_success.join(" -> ")
end
# vim: set ts=2 sw=2 et :
