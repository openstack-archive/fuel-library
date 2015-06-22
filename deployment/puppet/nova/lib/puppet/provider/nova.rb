# Run test ie with: rspec spec/unit/provider/nova_spec.rb

require 'puppet/util/inifile'

class Puppet::Provider::Nova < Puppet::Provider

  def self.conf_filename
    '/etc/nova/nova.conf'
  end

  def self.withenv(hash, &block)
    saved = ENV.to_hash
    hash.each do |name, val|
      ENV[name.to_s] = val
    end

    yield
  ensure
    ENV.clear
    saved.each do |name, val|
      ENV[name] = val
    end
  end

  def self.nova_conf
    return @nova_conf if @nova_conf
    @nova_conf = Puppet::Util::IniConfig::File.new
    @nova_conf.read(conf_filename)
    @nova_conf
  end

  def self.nova_credentials
    @nova_credentials ||= get_nova_credentials
  end

  def nova_credentials
    self.class.nova_credentials
  end

  def self.get_nova_credentials
    #needed keys for authentication
    auth_keys = ['auth_host', 'auth_port', 'auth_protocol',
                 'admin_tenant_name', 'admin_user', 'admin_password']
    conf = nova_conf
    if conf and conf['keystone_authtoken'] and
        auth_keys.all?{|k| !conf['keystone_authtoken'][k].nil?}
      return Hash[ auth_keys.map \
                   { |k| [k, conf['keystone_authtoken'][k].strip] } ]
    else
      raise(Puppet::Error, "File: #{conf_filename} does not contain all " +
            "required sections.  Nova types will not work if nova is not " +
            "correctly configured.")
    end
  end

  def self.get_auth_endpoint
    q = nova_credentials
    "#{q['auth_protocol']}://#{q['auth_host']}:#{q['auth_port']}/v2.0/"
  end

  def self.auth_endpoint
    @auth_endpoint ||= get_auth_endpoint
  end

  def self.auth_nova(*args)
    q = nova_credentials
    authenv = {
      :OS_AUTH_URL    => self.auth_endpoint,
      :OS_USERNAME    => q['admin_user'],
      :OS_TENANT_NAME => q['admin_tenant_name'],
      :OS_PASSWORD    => q['admin_password']
    }
    begin
      withenv authenv do
        nova(args)
      end
    rescue Exception => e
      if (e.message =~ /\[Errno 111\] Connection refused/) or
          (e.message =~ /\(HTTP 400\)/)
        sleep 10
        withenv authenv do
          nova(args)
        end
      else
       raise(e)
      end
    end
  end

  def auth_nova(*args)
    self.class.auth_nova(args)
  end

  def self.reset
    @nova_conf = nil
    @nova_credentials = nil
  end

  def self.str2hash(s)
    #parse string
    if s.include? "="
      k, v = s.split("=", 2)
      return {k.gsub(/'/, "") => v.gsub(/'/, "")}
    else
      return s.gsub(/'/, "")
    end
  end

  def self.str2list(s)
    #parse string
    if s.include? ","
      if s.include? "="
        new = {}
      else
        new = []
      end
      s.split(",").each do |el|
        ret = str2hash(el.strip())
        if s.include? "="
          new.update(ret)
        else
          new.push(ret)
        end
      end
      return new
    else
      return str2hash(s.strip())
    end
  end

  def self.cliout2list(output)
    #don't proceed with empty output
    if output.empty?
      return []
    end
    lines = []
    output.each_line do |line|
      #ignore lines starting with '+'
      if not line.match("^\\+")
        #split line at '|' and remove useless information
        line = line.gsub(/^\| /, "").gsub(/ \|$/, "").gsub(/[\n]+/, "")
        line = line.split("|").map do |el|
          el.strip().gsub(/^-$/, "")
        end
        #check every element for list
        line = line.map do |el|
          el = str2list(el)
        end
        lines.push(line)
      end
    end
    #create a list of hashes and return the list
    hash_list = []
    header = lines[0]
    lines[1..-1].each do |line|
      hash_list.push(Hash[header.zip(line)])
    end
    return hash_list
  end

  def self.nova_aggregate_resources_ids
    #produce a list of hashes with Id=>Name pairs
    lines = []
    #run command
    cmd_output = auth_nova("aggregate-list")
    #parse output
    hash_list = cliout2list(cmd_output)
    #only interessted in Id and Name
    hash_list.map{ |e| e.delete("Availability Zone")}
    hash_list.map{ |e| e['Id'] = e['Id'].to_i}
  return hash_list
  end

  def self.nova_aggregate_resources_get_name_by_id(name)
    #find the id by the given name
    nova_aggregate_resources_ids.each do |entry|
      if entry["Name"] == name
        return entry["Id"]
      end
    end
    #name not found
    return nil
  end

  def self.nova_aggregate_resources_attr(id)
    #run command to get details for given Id
    cmd_output = auth_nova("aggregate-details", id)
    list = cliout2list(cmd_output)[0]
    if ! list["Hosts"].is_a?(Array)
      if list["Hosts"] == ""
        list["Hosts"] = []
      else
        list["Hosts"] = [ list["Hosts"] ]
      end
    end
    return list
  end

end
