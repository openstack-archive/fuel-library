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
    admin_port = keystone_file['DEFAULT']['admin_port'] ? keystone_file['DEFAULT']['admin_port'].strip : '35357'
    if keystone_file and keystone_file['DEFAULT'] and keystone_file['DEFAULT']['bind_host']
      host = keystone_file['DEFAULT']['bind_host'].strip
      if host == "0.0.0.0"
        host = "127.0.0.1"
      end
    else
      host = "127.0.0.1"
    end
    "http://#{host}:#{admin_port}/v2.0/"
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

  def self.auth_keystone(*args)
    rv = nil
    retries = 60
    loop do
      begin
        rv = keystone('--os-token', admin_token, '--os-endpoint', admin_endpoint, args)
        break
      rescue Exception => e
        if e.message =~ /(\(HTTP\s+400\))|(\[Errno 111\]\s+Connection\s+refused)|(503\s+Service\s+Unavailable)|(Max\s+retries\s+exceeded)|(Unable\sto\sestablish\sconnection\sto)|\(HTTP\s+50[34]\)/
          notice("Can't connect to keystone backend. Waiting for retry...")
          retries -= 1
          sleep 2
          if retries <= 1
            notice("Can't connect to keystone backend. No more retries, auth failed")
            raise(e)
            #break
          end
        else
          raise(e)
          #break
        end
      end
    end
    return rv
  end

  def auth_keystone(*args)
    self.class.auth_keystone(args)
  end

  private

    def self.list_keystone_objects(type, number_columns, *args)
      # this assumes that all returned objects are of the form
      # id, name, enabled_state, OTHER
      # number_columns can be a Fixnum or an Array of possible values that can be returned
      list = (auth_keystone("#{type}-list", args).split("\n")[3..-2] || []).select{ |line| line =~ /^\|.*\|$/ }.reject{ |line| line =~ /^\|\s+id\s+.*\|$/}.collect do |line|

        row = line.split(/\|/)[1..-1]
        row = row.map {|x| x.strip }
        # if both checks fail then we have a mismatch between what was expected and what was received
        if (number_columns.class == Array and !number_columns.include? row.size) or (number_columns.class == Fixnum and row.size != number_columns)
          raise(Puppet::Error, "Expected #{number_columns} columns for #{type} row, found #{row.size}. Line #{line}")
        end
        row
      end
	debug(list.inspect)
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
end
