require 'ipaddr'
require 'pp'
require 'puppetx/l23_utils'
require 'puppetx/l23_network_scheme'
require 'puppetx/l23_hash_tools'

Puppet::Parser::Functions::newfunction(:configure_default_route, :type => :rvalue, :doc => <<-EOS
This function get Hash of network interfaces and endpoints configuration and realized it.
EOS
) do |argv|
  raise Puppet::ParseError, 'configure_default_route(): Arguments: network_scheme, master_ip, management_vrouter_vip' if argv.size != 3

  network_scheme = argv[0]
  master_ip = argv[1]
  management_vrouter_vip = argv[2]

  raise Puppet::ParseError, 'network_scheme is empty!' if network_scheme.nil?
  raise Puppet::ParseError, 'master_ip is empty!' if master_ip.nil?
  raise Puppet::ParseError, 'management_vrouter_vip is empty!' if management_vrouter_vip.nil?

  network_scheme = L23network.sanitize_keys_in_hash network_scheme
  network_scheme = L23network.sanitize_bool_in_hash network_scheme

  # we can't imagine, that user can write in this field, but we try to convert to numeric and compare
  if network_scheme[:version].to_s.to_f < 1.1
    raise Puppet::ParseError, 'configure_default_route(): You network_scheme hash has wrong format. This parser can work with v1.1 format, please convert you config.'
  end

  # collect L3::ifconfig properties from 'endpoints' section
  debug 'configure_default_route(): collect endpoints'
  endpoints = {}
  if network_scheme[:endpoints].is_a? Hash and network_scheme[:endpoints].any?
    network_scheme[:endpoints].each do |endpoint_name, endpoint_properties|
      endpoint_name = endpoint_name.to_sym
      endpoints[endpoint_name] = { :ipaddr => [] }
      if endpoint_properties and endpoint_properties.any?
        endpoint_properties.each do |endpoint_property_name, endpoint_property_value|
          endpoint_property_name = endpoint_property_name.to_s.tr('-', '_').to_sym
          if endpoint_property_name == :IP
            if ['none', 'dhcp', ''].include? endpoint_property_value.to_s
              # 'none' and 'dhcp' should be passed to resource not as list
              endpoints[endpoint_name][:ipaddr] = (endpoint_property_value.to_s == 'dhcp' ? 'dhcp' : 'none')
            elsif endpoint_property_value.is_a? Array
              # pass array of ip addresses validating every ip
              endpoint_property_value.each do |ip|
                begin
                  # validate ip address
                  IPAddr.new ip
                  endpoints[endpoint_name][:ipaddr] = [] unless endpoints[endpoint_name][:ipaddr]
                  endpoints[endpoint_name][:ipaddr] << ip
                rescue
                  raise Puppet::ParseError, "configure_default_route(): IP address '#{ip}' for endpoint '#{endpoint_name}' is wrong!"
                end
              end
            else
              raise Puppet::ParseError, "configure_default_route(): IP field for endpoint '#{endpoint_name}' must be array of IP addresses, 'dhcp' or 'none'"
            end
          else
            endpoints[endpoint_name][endpoint_property_name] = endpoint_property_value
          end
        end
      else
        endpoints[endpoint_name][:ipaddr] = 'none'
      end
    end
  else
    network_scheme[:endpoints] = {}
  end

  data = {}

  change_to_vrouter = network_scheme[:endpoints].find do |endpoint|
    endpoint[1][:gateway] == master_ip and endpoint[0] == :'br-fw-admin'
  end

  unless change_to_vrouter
    debug 'configure_default_route(): Will not change the default route to the vrouter IP address'
    return data
  end

  debug 'configure_default_route(): Change default route to vrouter ip address'
  interface_names = [:'br-mgmt', :'br-fw-admin']
  interface_names.each do |endpoint_name|
    next unless endpoints[endpoint_name]
    # collect properties for creating endpoint resource
    debug "configure_default_route(): Endpoint '#{endpoint_name}' will be created with additional properties:\n#{endpoints[endpoint_name].pretty_inspect}"
    resource_properties = {}
    endpoints[endpoint_name][:gateway] = management_vrouter_vip if endpoint_name == :'br-mgmt'
    endpoints[endpoint_name].each do |property, value|
      next if property == :gateway and endpoint_name == :'br-fw-admin'
      next unless value
      if property.to_s.downcase == 'routes'
        # TODO: support setting of routes?
      elsif %w(Hash Array).include? value.class.to_s
        # sanitize hash or array
        resource_properties[property.to_s] = L23network.reccursive_sanitize_hash(value)
      else
        # pass value as is
        resource_properties[property.to_s] = value
      end
    end
    # save resource parameters
    data[endpoint_name.to_s] = resource_properties
  end
  data
end

# vim: set ts=2 sw=2 et :
