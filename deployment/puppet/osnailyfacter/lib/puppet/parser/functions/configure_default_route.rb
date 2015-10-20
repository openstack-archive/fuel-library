require 'ipaddr'
require 'pp'
require 'puppetx/l23_utils'
require 'puppetx/l23_network_scheme'
require 'puppetx/l23_hash_tools'

Puppet::Parser::Functions::newfunction(:configure_default_route, :type => :rvalue, :doc => <<-EOS
This function gets hash of network endpoints configuration and check if fw-admin endpoint has gateway
and any network includes management vrouter vip address. If yes - it removes it and set default route
to vip of vrouter via management network, if no - it does nothing.
EOS
) do |argv|
  raise Puppet::ParseError, 'configure_default_route(): Arguments: network_scheme, management_vrouter_vip, fw_admin_int, management_int' if argv.size != 4

  network_scheme = argv[0]
  management_vrouter_vip = argv[1]
  fw_admin_int = argv[2].to_sym
  management_int = argv[3].to_sym

  raise Puppet::ParseError, 'network_scheme is empty!' if network_scheme.nil?
  raise Puppet::ParseError, 'management_vrouter_vip is empty!' if management_vrouter_vip.nil?
  raise Puppet::ParseError, 'fw_admin_int is empty!' if fw_admin_int.nil?
  raise Puppet::ParseError, 'management_int is empty!' if management_int.nil?

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


  change_to_vrouter = false

  endpoints[management_int][:ipaddr].each do |ipnet|
    change_to_vrouter = true if endpoints[fw_admin_int][:gateway] and IPAddr.new(ipnet).include?(IPAddr.new(management_vrouter_vip))
  end

  unless change_to_vrouter
    debug 'configure_default_route(): Will not change the default route to the vrouter IP address'
    return {}
  end

  data = {}
  debug 'configure_default_route(): Change default route to vrouter ip address'
  interface_names = [ fw_admin_int, management_int ]
  previous = nil
  interface_names.each do |endpoint_name|
    next unless endpoints[endpoint_name]
    # collect properties for creating endpoint resource
    resource_properties = {}
    endpoints[endpoint_name][:gateway] = management_vrouter_vip if endpoint_name == management_int
    endpoints[endpoint_name].each do |property, value|
      value = :absent if property == :gateway and endpoint_name == fw_admin_int
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
    resource_properties['require'] = previous if previous
    # save resource parameters
    debug "configure_default_route(): Endpoint '#{endpoint_name}' will be created with additional properties:\n#{resource_properties.pretty_inspect}"
    function_create_resources(['l23network::l3::ifconfig', {
          "#{endpoint_name}" => resource_properties
        }])
    previous = "L23network::L3::Ifconfig[#{endpoint_name}]"
    data[endpoint_name.to_s] = resource_properties
  end
  data
end

# vim: set ts=2 sw=2 et :
