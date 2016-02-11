Puppet::Parser::Functions::newfunction(:get_ssl_property, :type => :rvalue, :doc => <<-EOS
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

    fail "You should provide all arguments!" if args.length != 6

    fail "You should provide hash as a first argument!" if not use_ssl_hash.is_a?(Hash)
    fail "You should provide hash as a second argument!" if not public_ssl_hash.is_a?(Hash)
    fail "You should provide 'name' for service as a third argument!" if service_name.empty?
    fail "You should provide 'type' for service as a fourth argument!" if service_type.empty?
    fail "You should provide 'type' for resource as a fifth argument!" if resource_type.empty?
    fail "You should provide some default value as a sixth argument!" if default_value.nil?

    class GetData
      def initialize(use_ssl_hash, public_ssl_hash, default_value, service_type, service_name, resource_type)
        @use_ssl_hash = use_ssl_hash
        @public_ssl_hash = public_ssl_hash
        if default_value.is_a?(Array)
          default_value.each do |x|
            if !!x == x or (x.is_a?(String) and !x.empty?)
              @default_value = x
              break
            end
          end
        else
          @default_value = default_value
        end
        @service_type = service_type
        @service_name = service_name
        @resource_type = resource_type
      end

      def get_protocol(flag)
        if (@use_ssl_hash.empty? and @public_ssl_hash.empty?) or (@use_ssl_hash.empty? and @service_type != 'public')
          return @default_value
        end
        flag ? 'https' : 'http'
      end

      def get_path(is_custom)
        if (@use_ssl_hash.empty? and @public_ssl_hash.empty?) or (@use_ssl_hash.empty? and @service_type != 'public')
          return @default_value
        end
        path = '/var/lib/astute/haproxy/' + @service_type.to_s + '_haproxy.pem'
        if is_custom
          path = '/var/lib/astute/haproxy/' + @service_type.to_s + '_' + @service_name.to_s + '.pem'
        end
        path
      end

      def get_usage(flag)
        if flag.nil?
          return @default_value
        end
        flag
      end

      def get_hostname(is_custom)
        if (@use_ssl_hash.empty? and @public_ssl_hash.empty?) or (@use_ssl_hash.empty? and @service_type != 'public')
          return @default_value
        end
        hostname = @public_ssl_hash[@resource_type] or @default_value
        if is_custom
          hostname = @use_ssl_hash["#{@service_name}_#{@service_type}_hostname"] or @default_value
        end
        hostname
      end

      def default_value
        @default_value
      end
    end

    i = GetData.new(use_ssl_hash, public_ssl_hash, default_value, service_type, service_name, resource_type)
    case resource_type.to_s
    when 'protocol'
      if not use_ssl_hash.empty?
        i.get_protocol(use_ssl_hash["#{service_name}_#{service_type}"])
      else
        if service_name == 'horizon' and service_type == 'public'
          i.get_protocol(public_ssl_hash['horizon'])
        elsif service_type == 'public'
          i.get_protocol(public_ssl_hash['services'])
        else
          i.default_value
        end
      end

    when 'hostname'
      if not use_ssl_hash.empty?
        i.get_hostname(true)
      else
        i.get_hostname(false)
      end

    when 'usage'
      if not use_ssl_hash.empty?
        i.get_usage(use_ssl_hash["#{service_name}_#{service_type}"])
      else
        if service_name == 'horizon' and service_type == 'public'
          i.get_usage(public_ssl_hash['horizon'])
        elsif service_type == 'public'
          i.get_usage(public_ssl_hash['services'])
        else
          i.default_value
        end
      end

    when 'path'
      if not use_ssl_hash.empty?
        i.get_path(true)
      else
        i.get_path(false)
      end

    else
      fail "You should choose 'protocol', 'hostname', 'usage' or 'path' for service!"
    end
end

