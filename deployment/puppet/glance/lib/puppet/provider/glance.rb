# Since there's only one glance type for now,
# this probably could have all gone in the provider file.
# But maybe this is good long-term.
require 'puppet/util/inifile'
class Puppet::Provider::Glance < Puppet::Provider

  def self.glance_credentials
    @glance_credentials ||= get_glance_credentials
  end

  def self.get_glance_credentials
    if glance_file and glance_file['keystone_authtoken'] and
      glance_file['keystone_authtoken']['auth_host'] and
      glance_file['keystone_authtoken']['auth_port'] and
      glance_file['keystone_authtoken']['auth_protocol'] and
      glance_file['keystone_authtoken']['admin_tenant_name'] and
      glance_file['keystone_authtoken']['admin_user'] and
      glance_file['keystone_authtoken']['admin_password'] and
      glance_file['DEFAULT']['os_region_name']

        g = {}
        g['auth_host'] = glance_file['keystone_authtoken']['auth_host'].strip
        g['auth_port'] = glance_file['keystone_authtoken']['auth_port'].strip
        g['auth_protocol'] = glance_file['keystone_authtoken']['auth_protocol'].strip
        g['admin_tenant_name'] = glance_file['keystone_authtoken']['admin_tenant_name'].strip
        g['admin_user'] = glance_file['keystone_authtoken']['admin_user'].strip
        g['admin_password'] = glance_file['keystone_authtoken']['admin_password'].strip
        g['os_region_name'] = glance_file['DEFAULT']['os_region_name'].strip

        # auth_admin_prefix not required to be set.
        g['auth_admin_prefix'] = (glance_file['keystone_authtoken']['auth_admin_prefix'] || '').strip

        return g
    else
      raise(Puppet::Error, 'File: /etc/glance/glance-api.conf does not contain all required sections.')
    end
  end

  def glance_credentials
    self.class.glance_credentials
  end

  def self.auth_endpoint
    @auth_endpoint ||= get_auth_endpoint
  end

  def self.get_auth_endpoint
    g = glance_credentials
    "#{g['auth_protocol']}://#{g['auth_host']}:#{g['auth_port']}#{g['auth_admin_prefix']}/v2.0/"
  end

  def self.glance_file
    return @glance_file if @glance_file
    @glance_file = Puppet::Util::IniConfig::File.new
    @glance_file.read('/etc/glance/glance-api.conf')
    @glance_file
  end

  def self.glance_hash
    @glance_hash ||= build_glance_hash
  end

  def self.reset
    @glance_hash        = nil
    @glance_file        = nil
    @glance_credentials = nil
    @auth_endpoint      = nil
  end

  def glance_hash
    self.class.glance_hash
  end

  def self.auth_glance(*args)
    begin
      g = glance_credentials
      remove_warnings(glance('--os-tenant-name', g['admin_tenant_name'], '--os-username', g['admin_user'], '--os-password', g['admin_password'], '--os-region-name', g['os_region_name'], '--os-auth-url', auth_endpoint, args))
    rescue Exception => e
      if (e.message =~ /\[Errno 111\] Connection refused/) or (e.message =~ /\(HTTP 400\)/) or (e.message =~ /HTTP Unable to establish connection/)
        sleep 10
        remove_warnings(glance('--os-tenant-name', g['admin_tenant_name'], '--os-username', g['admin_user'], '--os-password', g['admin_password'], '--os-region-name', g['os_region_name'], '--os-auth-url', auth_endpoint, args))
      else
        raise(e)
      end
    end
  end

  def auth_glance(*args)
    self.class.auth_glance(args)
  end

  def self.auth_glance_stdin(*args)
    begin
      g = glance_credentials
      command = "glance --os-tenant-name #{g['admin_tenant_name']} --os-username #{g['admin_user']} --os-password #{g['admin_password']} --os-region-name #{g['os_region_name']} --os-auth-url #{auth_endpoint} #{args.join(' ')}"

      # This is a horrible, horrible hack
      # Redirect stderr to stdout in order to report errors
      # Ignore good output
      err = `#{command} 3>&1 1>/dev/null 2>&3`
      if $? != 0
        raise(Puppet::Error, err)
      end
    end
  end

  def auth_glance_stdin(*args)
    self.class.auth_glance_stdin(args)
  end

  private
    def self.list_glance_images
      ids = []
      (auth_glance('image-list').split("\n")[3..-2] || []).collect do |line|
        ids << line.split('|')[1].strip()
      end
      return ids
    end

    def self.get_glance_image_attr(id, attr)
      (auth_glance('image-show', id).split("\n") || []).collect do |line|
        if line =~ /^#{attr}:/
          return line.split(': ')[1..-1]
        end
      end
    end

    def self.get_glance_image_attrs(id)
      attrs = {}
      (auth_glance('image-show', id).split("\n")[3..-2] || []).collect do |line|
        attrs[line.split('|')[1].strip()] = line.split('|')[2].strip()
      end
      return attrs
    end

    def parse_table(table)
      # parse the table into an array of maps with a simplistic state machine
      found_header = false
      parsed_header = false
      keys = nil
      results = []
      table.split("\n").collect do |line|
        # look for the header
        if not found_header
          if line =~ /^\+[-|+]+\+$/
            found_header = true
            nil
          end
        # look for the key names in the table header
        elsif not parsed_header
          if line =~ /^(\|\s*[:alpha:]\s*)|$/
            keys = line.split('|').map(&:strip)
            parsed_header = true
          end
        # parse the values in the rest of the table
        elsif line =~ /^|.*|$/
          values = line.split('|').map(&:strip)
          result = Hash[keys.zip values]
          results << result
        end
      end
      results
    end

    # Remove warning from the output. This is a temporary hack until
    # things will be refactored to use the REST API
    def self.remove_warnings(results)
      found_header = false
      in_warning = false
      results.split("\n").collect do |line|
        unless found_header
          if line =~ /^\+[-\+]+\+$/ # Matches upper and lower box borders
            in_warning = false
            found_header = true
            line
          elsif line =~ /^WARNING/ or line =~ /UserWarning/ or in_warning
            # warnings can be multi line, we have to skip all of them
            in_warning = true
            nil
          else
            line
          end
        else
          line
        end
      end.compact.join("\n")
    end
end
