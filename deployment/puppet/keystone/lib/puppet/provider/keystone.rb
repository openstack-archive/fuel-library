require 'puppet/util/inifile'
class Puppet::Provider::Keystone < Puppet::Provider

  # retrieves the current token from keystone.conf
  def self.admin_token
    @admin_token ||= get_admin_token
  end

  def self.get_admin_token
    if keystone_file and keystone_file['DEFAULT'] and keystone_file['DEFAULT']['admin_token']
      return "#{keystone_file['DEFAULT']['admin_token'].strip}"
    else
      raise(Puppet::Error, "File: /etc/keystone/keystone.conf does not contain a section DEFAULT with the admin_token specified. Keystone types will not work if keystone is not correctly configured")
    end
  end

  def self.admin_endpoint
    @admin_endpoint ||= get_admin_endpoint
  end

  def self.get_admin_endpoint
    admin_endpoint = keystone_file['DEFAULT']['admin_endpoint'] ? keystone_file['DEFAULT']['admin_endpoint'].strip : nil
    return admin_endpoint if admin_endpoint

    admin_port = keystone_file['DEFAULT']['admin_port'] ? keystone_file['DEFAULT']['admin_port'].strip : '35357'
    ssl = keystone_file['ssl'] && keystone_file['ssl']['enable'] ? keystone_file['ssl']['enable'].strip.downcase == 'true' : false
    protocol = ssl ? 'https' : 'http'
    if keystone_file and keystone_file['DEFAULT'] and keystone_file['DEFAULT']['bind_host']
      host = keystone_file['DEFAULT']['bind_host'].strip
      if host == "0.0.0.0"
        host = "127.0.0.1"
      end
    else
      host = "127.0.0.1"
    end
    "#{protocol}://#{host}:#{admin_port}/v2.0/"
  end

  def self.keystone_file
    return @keystone_file if @keystone_file
    @keystone_file = Puppet::Util::IniConfig::File.new
    @keystone_file.read('/etc/keystone/keystone.conf')
    @keystone_file
  end

  def self.tenant_hash
    @tenant_hash ||= build_tenant_hash
  end

  def tenant_hash
    self.class.tenant_hash
  end

  def self.reset
    @admin_endpoint = nil
    @tenant_hash    = nil
    @admin_token    = nil
    @keystone_file  = nil
  end

  # the path to withenv changes between versions of puppet, so redefining this function here,
  # Run some code with a specific environment.  Resets the environment at the end of the code.
  def self.withenv(hash, &block)
    saved = ENV.to_hash
    hash.each do |name, val|
      ENV[name.to_s] = val
    end
    block.call
  ensure
    ENV.clear
    saved.each do |name, val|
      ENV[name] = val
    end
  end

  def self.auth_keystone(*args)
    authenv = {:OS_SERVICE_TOKEN => admin_token}
    begin
      withenv authenv do
        remove_warnings(keystone('--os-endpoint', admin_endpoint, args))
      end
    rescue Exception => e
      if e.message =~ /(\(HTTP\s+400\))|(\[Errno 111\]\s+Connection\s+refused)|(503\s+Service\s+Unavailable)|(Max\s+retries\s+exceeded)|(Unable\s+to\s+establish\s+connection)/
        sleep 10
        withenv authenv do
          remove_warnings(keystone('--os-endpoint', admin_endpoint, args))
        end
      else
        raise(e)
      end
    end
  end

  def auth_keystone(*args)
    self.class.auth_keystone(args)
  end

  def self.creds_keystone(name, tenant, password, *args)
    authenv = {:OS_USERNAME => name, :OS_TENANT_NAME => tenant, :OS_PASSWORD => password}
    begin
      withenv authenv do
        remove_warnings(keystone('--os-auth-url', admin_endpoint, args))
      end
    rescue Exception => e
      if e.message =~ /(\(HTTP\s+400\))|(\[Errno 111\]\s+Connection\s+refused)|(503\s+Service\s+Unavailable)|(Max\s+retries\s+exceeded)|(Unable\s+to\s+establish\s+connection)/
        sleep 10
        withenv authenv do
          remove_warnings(keystone('--os-auth-url', admin_endpoint, args))
        end
      else
        raise(e)
      end
    end
   end

   def creds_keystone(name, tenant, password, *args)
     self.class.creds_keystone(name, tenant, password, args)
   end

  def self.parse_keystone_object(data)
    # Parse the output of [type]-{create,get} into a hash
    attrs = {}
    header_lines = 3
    footer_lines = 1
    data.split("\n")[header_lines...-footer_lines].each do |line|
      if match_data = /\|\s([^|]+)\s\|\s([^|]+)\s\|/.match(line)
        attrs[match_data[1].strip] = match_data[2].strip
      end
    end
    attrs
  end

  private

    def self.list_keystone_objects(type, number_columns, *args)
      # this assumes that all returned objects are of the form
      # id, name, enabled_state, OTHER
      # number_columns can be a Fixnum or an Array of possible values that can be returned
      list = (auth_keystone("#{type}-list", args).split("\n")[3..-2] || []).collect do |line|
        row = line.split(/\|/)[1..-1]
        row = row.map {|x| x.strip }
        # if both checks fail then we have a mismatch between what was expected and what was received
        if (number_columns.class == Array and !number_columns.include? row.size) or (number_columns.class == Fixnum and row.size != number_columns)
          raise(Puppet::Error, "Expected #{number_columns} columns for #{type} row, found #{row.size}. Line #{line}")
        end
        row
      end
      list
    end

    def self.get_keystone_object(type, id, attr)
      id = id.chomp
      auth_keystone("#{type}-get", id).split(/\|\n/m).each do |line|
        if line =~ /\|(\s+)?#{attr}(\s+)?\|/
          if line.kind_of?(Array)
            return line[0].split("|")[2].strip
          else
            return  line.split("|")[2].strip
          end
        else
          nil
        end
      end
      raise(Puppet::Error, "Could not find colummn #{attr} when getting #{type} #{id}")
    end

    # remove warning from the output. this is a temporary hack until
    # I refactor things to use the the rest API
    def self.remove_warnings(results)
      found_header = false
      in_warning = false
      results.split("\n").collect do |line|
        unless found_header
          if line =~ /^\+[-\+]+\+$/
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
