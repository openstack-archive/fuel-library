require 'ipaddr'
require 'yaml'
require 'forwardable'
require 'puppet/parser'
require 'puppet/parser/templatewrapper'
require 'puppet/resource/type_collection_helper'
require 'puppet/util/methodhelper'
require 'puppetx/l23_utils'
require 'puppetx/l23_network_scheme'
require 'hiera'



Puppet::Parser::Functions::newfunction(:configure_default_route, :type => :rvalue, :doc => <<-EOS
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
        :ifconfig => 'l23network::l3::ifconfig'
      }
    end

    if argv.size != 0
      raise(Puppet::ParseError, "configure_default_route(): Wrong number of arguments.")
    end
    config_hash = L23network::Scheme.get_config(lookupvar('l3_fqdn_hostname'))
    if config_hash.nil?
      raise(Puppet::ParseError, "configure_default_route(...): You must call prepare_network_config(...) first!")
    end

    # we can't imagine, that user can write in this field, but we try to convert to numeric and compare
    if config_hash[:version].to_s.to_f < 1.1
      raise(Puppet::ParseError, "configure_default_route(...): You network_scheme hash has wrong format.\nThis parser can work with v1.1 format, please convert you config.")
    end

    # collect L3::ifconfig properties from 'endpoints' section
    debug("configure_default_route(): collect endpoints")
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
                raise(Puppet::ParseError, "configure_default_route(): IP field for endpoint '#{e_name}' must be array of IP addresses, 'dhcp' or 'none'.")
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
                    raise(Puppet::ParseError, "configure_default_route(): IP address '#{ip}' for endpoint '#{e_name}' wrong!.")
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

    ENV['LANG'] = 'C'
    hiera = Hiera.new(:config => '/etc/hiera.yaml')
    master_ip = hiera.lookup('master_ip', false, {})
    management_vrouter_vip = hiera.lookup('management_vrouter_vip', false, {})

    change_to_vrouter = false
    config_hash[:endpoints].each do | endpoint |
       change_to_vrouter = true if ( endpoint[1][:gateway] == master_ip && endpoint[0] == :'br-fw-admin' )
    end

    if !change_to_vrouter
      debug("configure_default_route(): Not change default route to vrouter ip address")
      puts "configure_default_route(): Not change default route to vrouter ip address"
      return
    end

    debug("configure_default_route(): Change default route to vrouter ip address")
    [ :'br-mgmt' , :'br-fw-admin' ].each do | endpoint_name |
      if endpoints[endpoint_name]
        resource_properties = { }
        # create resource
        resource = res_factory[:ifconfig]
        debug("configure_default_route(): Endpoint '#{endpoint_name}' will be created with additional properties \n#{endpoints[endpoint_name].to_yaml.gsub('!ruby/sym ',':')}")
        # collect properties for creating endpoint resource
        endpoints[endpoint_name][:gateway] = management_vrouter_vip if endpoint_name == :'br-mgmt'
        endpoints[endpoint_name].each_pair do |k,v|
          next if k == :gateway && endpoint_name == :'br-fw-admin'
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
        function_create_resources([resource, {
          "#{endpoint_name}" => resource_properties
        }])
      end
    end

end
# vim: set ts=2 sw=2 et :
