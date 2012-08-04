# Since there's only one glance type for now,
# this probably could have all gone in the provider file.
# But maybe this is good long-term.
require 'puppet/util/inifile'
class Puppet::Provider::Glance < Puppet::Provider

  def self.glance_credentials
    @glance_credentials ||= get_glance_credentials
  end

  def self.get_glance_credentials
    if glance_file and glance_file['filter:authtoken'] and 
      glance_file['filter:authtoken']['auth_host'] and
      glance_file['filter:authtoken']['auth_port'] and
      glance_file['filter:authtoken']['auth_protocol'] and
      glance_file['filter:authtoken']['admin_tenant_name'] and
      glance_file['filter:authtoken']['admin_user'] and
      glance_file['filter:authtoken']['admin_password']

        g = {}
        g['auth_host'] = glance_file['filter:authtoken']['auth_host'].strip
        g['auth_port'] = glance_file['filter:authtoken']['auth_port'].strip
        g['auth_protocol'] = glance_file['filter:authtoken']['auth_protocol'].strip
        g['admin_tenant_name'] = glance_file['filter:authtoken']['admin_tenant_name'].strip
        g['admin_user'] = glance_file['filter:authtoken']['admin_user'].strip
        g['admin_password'] = glance_file['filter:authtoken']['admin_password'].strip
        return g
    else
      raise(Puppet::Error, 'File: /etc/glance/glance-api-paste.ini does not contain all required sections.')
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
    "#{g['auth_protocol']}://#{g['auth_host']}:#{g['auth_port']}/v2.0/"
  end

  def self.glance_file
    return @glance_file if @glance_file
    @glance_file = Puppet::Util::IniConfig::File.new
    @glance_file.read('/etc/glance/glance-api-paste.ini')
    @glance_file
  end

  def self.glance_hash
    @glance_hash ||= build_glance_hash
  end

  def glance_hash
    self.class.glance_hash
  end

  def self.auth_glance(*args)
    begin
      g = glance_credentials
      glance('-T', g['admin_tenant_name'], '-I', g['admin_user'], '-K', g['admin_password'], '-N', auth_endpoint, args)
    rescue Exception => e
      # Will probably add conditions later
      raise(e)
    end
  end

  def auth_glance(*args)
    self.class.auth_glance(args)
  end

  def self.auth_glance_stdin(*args)
    begin
      g = glance_credentials
      command = "glance --silent-upload -T #{g['admin_tenant_name']} -I #{g['admin_user']} -K #{g['admin_password']} -N #{auth_endpoint} #{args.join(' ')}"

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
      (auth_glance('index').split("\n")[2..-1] || []).collect do |line|
        ids << line.split[0]
      end
      return ids
    end

    def self.get_glance_image_attr(id, attr)
      (auth_glance('show', id).split("\n") || []).collect do |line|
        if line =~ /^#{attr}:/
          return line.split(': ')[1..-1]
        end
      end
    end

    def self.get_glance_image_attrs(id)
      attrs = {}
      (auth_glance('show', id).split("\n") || []).collect do |line|
        attrs[line.split(': ').first.downcase] = line.split(': ')[1..-1].to_s
      end
      return attrs
    end

end
