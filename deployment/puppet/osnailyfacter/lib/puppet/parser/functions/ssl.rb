module Puppet::Parser::Functions
  newfunction(:ssl, :type => :rvalue, :doc => <<-EOS
Return the needed values for services
  EOS
  ) do |args|
    use_ssl_hash = args[0]
    public_ssl_hash = args[1]
    service_name = args[2]
    service_type = args[3]
    resource_type = args[4]
    default_value = args[5]

    rval = false
    fail "You should provide 'name' for service!" if service_name.nil?

    check_ns_public = service_type.to_s == 'public'

    check_ssl = false
    check_ssl = true if use_ssl_hash["#{service_name}_#{service_type}"]
    check_ssl = true if check_ns_public and public_ssl_hash['services']

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
        rval = function_pick(default_value)
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
