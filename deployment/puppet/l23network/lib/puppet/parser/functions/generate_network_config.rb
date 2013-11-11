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
      if not rv[:interfaces].is_a? Array or rv[:interfaces].size() != 2
        raise(Puppet::ParseError, "Transformation bond '#{name}' have wrong 'interfaces' parameter.")
      end
      # rv[:interfaces].each do |i|
      #   if
      # end
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

    Puppet.debug "stage1@generate_network_config:config_hash: #{config_hash.inspect}"

    # define internal puppet parameters for creating resources
    res_factory = {
      :br      => { :name_of_resource => 'l23network::l2::bridge' },
      :port    => { :name_of_resource => 'l23network::l2::port' },
      :bond    => { :name_of_resource => 'l23network::l2::bond' },
      :patch   => { :name_of_resource => 'l23network::l2::patch' },
      :ifconfig=> { :name_of_resource => 'l23network::l3::ifconfig' }
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

    Puppet.debug "stage2@generate_network_config:res_factory: #{res_factory.inspect}"

    # collect interfaces and endpoints
    endpoints = {}
    born_ports = []
    config_hash[:interfaces].each do |int_name, int_properties|
      int_name = int_name.to_sym()
      endpoints[int_name] = create_endpoint()
      born_ports.insert(-1, int_name)
    end

    Puppet.debug "stage3@generate_network_config:endpoints: #{endpoints.inspect}"

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

    Puppet.debug "stage4@generate_network_config:endpoints: #{endpoints.inspect}"

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

      Puppet.debug "stage5@generate_network_config:action: #{action.inspect}"

      trans = L23network.sanitize_transformation(t)
      resource = res_factory[action][:resource]
      p_resource = Puppet::Parser::Resource.new(
          res_factory[action][:name_of_resource],
          trans[:name],
          :scope => self,
          :source => resource
      )

      Puppet.debug "stage6@generate_network_config:p_resource: #{p_resource.inspect}"

      trans.select{|k,v| k != :action}.each do |k,v|
        p_resource.set_parameter(k,v)
      end

      Puppet.debug "stage7@generate_network_config:p_resource: #{p_resource.inspect}"

      p_resource.set_parameter(:require, [previous]) if previous
      resource.instantiate_resource(self, p_resource)
      compiler.add_resource(self, p_resource)
      transformation_success.insert(-1, "#{t[:action].strip()}(#{trans[:name]})")
      born_ports.insert(-1, trans[:name].to_sym()) if action != :patch
      previous = p_resource.to_s
    end

    # check for all in endpoints are in interfaces or born by transformation
    config_hash[:endpoints].each do |e_name, e_properties|
      if not born_ports.index(e_name.to_sym())
        raise(Puppet::ParseError, "generate_network_config(): Endpoint '#{e_name}' not found in interfaces or transformations result.")
      end
    end
    # execute interfaces and endpoints
    # may be in future we will move interfaces before transformations
    endpoints.each do |endpoint_name, endpoint_body|
      # create resource
      resource = res_factory[:ifconfig][:resource]
      p_resource = Puppet::Parser::Resource.new(
          res_factory[:ifconfig][:name_of_resource],
          endpoint_name,
          :scope => self,
          :source => resource
      )

      Puppet.debug "stage8@generate_network_config:p_resource: #{p_resource.inspect}"

      p_resource.set_parameter(:interface, endpoint_name)

      Puppet.debug "stage9@generate_network_config:p_resource: #{p_resource.inspect}"

      # set ipaddresses
      if endpoint_body[:IP].empty?
        p_resource.set_parameter(:ipaddr, 'none')
        Puppet.debug "stage10@generate_network_config:p_resource: #{p_resource.inspect}"
      elsif ['none','dhcp'].index(endpoint_body[:IP][0])
        p_resource.set_parameter(:ipaddr, endpoint_body[:IP][0])
        Puppet.debug "stage11@generate_network_config:p_resource: #{p_resource.inspect}"
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
        Puppet.debug "stage12@generate_network_config:p_resource: #{p_resource.inspect}"
      end
      #set another (see L23network::l3::ifconfig DOC) parametres
      endpoint_body[:properties].each do |k,v|
        p_resource.set_parameter(k,v)
      end

      Puppet.debug "stage13@generate_network_config:p_resource: #{p_resource.inspect}"

      p_resource.set_parameter(:require, [previous]) if previous
      resource.instantiate_resource(self, p_resource)
      compiler.add_resource(self, p_resource)
      transformation_success.insert(-1, "endpoint(#{endpoint_name})")

      Puppet.debug "stage14@generate_network_config:transformation_success: #{transformation_success.inspect}"

      previous = p_resource.to_s
    end

    Puppet.debug "stage15@generate_network_config:transformation_success: #{transformation_success.inspect}"

    return transformation_success.join(" -> ")
end
# vim: set ts=2 sw=2 et :
