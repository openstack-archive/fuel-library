module Puppet::Parser::Functions
  newfunction(:get_ssl_property, :type => :rvalue, :doc => <<-EOS
Get SSL properties for services based on SSL hashes
Parameters:
 use_ssl_hash - hash with data for all TLS settings of all services
 public_ssl_hash - auxiliary hash with data for public TLS settings
 service_name - name of service for which data should be returned
 service_type - type of endpoint
 resource_type - type of data needed to be retrieved
 default_value - array with potentially default values to pick

Return:
 value for resource type you asked
EOS
  ) do |args|
    use_ssl_hash, public_ssl_hash, service_name, service_type, resource_type, default_value = *args

    fail "You should provide all arguments!" if args.length != 5

    rval = false
    fail "You should provide hash as a first argument!" if not use_ssl_hash.is_a?(Hash)
    fail "You should provide hash as a second argument!" if not public_ssl_hash.is_a?(Hash)
    fail "You should provide 'name' for service as a third argument!" if service_name.empty?
    fail "You should provide 'type' for service as a fourth argument!" if service_type.empty?
    fail "You should provide 'type' for resource as a fifth argument!" if resource_type.empty?
    fail "You should provide some default value as a sixth argument!" if default_value.nil?

    check_ns_public = service_type.to_s == 'public'

    check_ssl = false
    check_ssl = true if use_ssl_hash["#{service_name}_#{service_type}"]
    check_ssl = true if check_ns_public and public_ssl_hash['services']
    check_ssl = true if use_ssl_hash.empty? and public_ssl_hash.empty? and default_value == 'https'
    check_ssl = true if use_ssl_hash.empty? and service_type != 'public' and default_value == 'https'
    check_ssl = true if use_ssl_hash.empty? and public_ssl_hash.empty? and resource_type == 'usage' and default_value
    check_ssl = true if use_ssl_hash.empty? and service_type != 'public' and resource_type == 'usage' and default_value

    case resource_type.to_s
    when 'protocol'
      rval = check_ssl ? 'https' : 'http'

    when 'hostname'
      if check_ssl and check_ns_public
        get_variables = function_try_get_value([use_ssl_hash, "#{service_name}_#{service_type}_#{resource_type}", ''])
        rval = function_pick([get_variables, public_ssl_hash[resource_type], *default_value])
      elsif check_ssl
        get_variables = function_try_get_value([use_ssl_hash, "#{service_name}_#{service_type}_#{resource_type}", ''])
        rval = function_pick([get_variables, *default_value])
      else
        rval = function_pick(default_value, false)
      end

    when 'usage'
      rval = check_ssl ? true : false

    when 'path'
      bpath = '/var/lib/astute/haproxy/'
      if check_ns_public
        if use_ssl_hash["#{service_name}_#{service_type}"]
          rval = bpath + service_type.to_s + '_' + service_name + '.pem'
        elsif public_ssl_hash['services']
          rval = bpath + service_type.to_s + '_haproxy.pem'
        else
          rval = ''
        end
      else
        rval = bpath + service_type.to_s + '_' + service_name + '.pem'
      end
    else
      fail "You should choose 'protocol', 'hostname', 'usage' or 'path' for service!"
    end
    rval
  end
end
