#
# Author: François Charlier <francois.charlier@enovance.com>
#

Puppet::Type.type(:mongodb_replset).provide(:mongo, :parent => Puppet::Provider::Mongodb) do

  desc "Manage hosts members for a replicaset."

  confine :true =>
    begin
      require 'json'
      true
    rescue LoadError
      false
    end

  commands :mongo => 'mongo'

  mk_resource_methods

  def initialize(resource={})
    super(resource)
    @property_flush = {}
  end

  def members=(hosts)
    @property_flush[:members] = hosts
  end

  def self.instances
    instance = get_replset_properties
    if instance
      # There can only be one replset per node
      [new(instance)]
    else
      []
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_flush[:ensure] = :present
    @property_flush[:members] = resource.should(:members)
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def flush
    set_members
    @property_hash = self.class.get_replset_properties
  end

  private

  def db_ismaster(host)
    mongo_command('db.isMaster()', host)
  end

  def rs_initiate(conf, master)
    return mongo_command("rs.initiate(#{conf})", master)
  end

  def rs_status(host)
    mongo_command('rs.status()', host)
  end

  def rs_add(host, master)
    mongo_command("rs.add('#{host}')", master)
  end

  def rs_remove(host, master)
    mongo_command("rs.remove('#{host}')", master)
  end

  def auth_enabled
    @resource[:auth_enabled]
  end

  def master_host(hosts)
    hosts.each do |host|
      status = db_ismaster(host)
      if status.has_key?('primary')
        return status['primary']
      end
    end
    false
  end

  def self.get_mongod_conf_file
    if File.exists? '/etc/mongod.conf'
      file = '/etc/mongod.conf'
    else
      file = '/etc/mongodb.conf'
    end
    file
  end

  def self.get_conn_string
    # TODO (spredzy) : Dirty hack
    # to make the rs.conf() run on
    # the proper mongodb connection
    # Since we don't have access to
    # instance properties at this time.
    hash = {}
    File.open(get_mongod_conf_file) do |fp|
      fp.each do |line|
        if !line.start_with?('#')
          key, value = line.chomp.split(/\s*=\s*/)
          hash[key] = value
        end
      end
    end

    if hash['bind_ip'] and ! hash['bind_ip'].eql? '0.0.0.0'
      ip_real = hash['bind_ip']
    else
      ip_real = '127.0.0.1'
    end

    if hash['port']
      port_real = hash['port']
    elsif !hash['port'] and hash['configsvr']
      port_real = 27019
    elsif !hash['port'] and hash['shardsvr']
      port_real = 27018
    else
      port_real = 27017
    end

    "#{ip_real}:#{port_real}"
  end

  def self.get_replset_properties
    conn_string = get_conn_string
    output = mongo_command('rs.conf()', conn_string)
    if output['members']
      members = output['members'].collect do |val|
        val['host']
      end
      props = {
        :name     => output['_id'],
        :ensure   => :present,
        :members  => members,
        :provider => :mongo,
      }
    else
      props = nil
    end
    Puppet.debug("MongoDB replset properties: #{props.inspect}")
    props
  end

  def alive_members(hosts)
    alive = []
    hosts.select do |host|
      begin
        Puppet.debug "Checking replicaset member #{host} ..."
        status = rs_status(host)
        if status.has_key?('errmsg') and status['errmsg'] == 'not running with --replSet'
          raise Puppet::Error, "Can't configure replicaset #{self.name}, host #{host} is not supposed to be part of a replicaset."
        end

        if auth_enabled and status.has_key?('errmsg') and (status['errmsg'].include? "unauthorized" or status['errmsg'].include? "not authorized")
          Puppet.warning "Host #{host} is available, but you are unauthorized because of authentication is enabled: #{auth_enabled}"
          alive.push(host)
        end

        if status.has_key?('set')
          if status['set'] != self.name
            raise Puppet::Error, "Can't configure replicaset #{self.name}, host #{host} is already part of another replicaset."
          end

          # This node is alive and supposed to be a member of our set
          Puppet.debug "Host #{self.name} is available for replset #{status['set']}"
          alive.push(host)
        elsif status.has_key?('info')
          Puppet.debug "Host #{self.name} is alive but unconfigured: #{status['info']}"
          alive.push(host)
        end

      rescue Puppet::ExecutionFailure
        Puppet.warning "Can't connect to replicaset member #{host}."
      end
    end
    alive
  end

  def primary?(hosts)
    hosts.select do |host|
      status = rs_status(host)
      if status['members']
        primary = status['members'].each{|member|  break member['stateStr'] == 'PRIMARY'}
        return true if primary
      end
    end
    return false
  end

  def alive_hosts
    if ! @property_flush[:members].empty?
      # Find the alive members so we don't try to add dead members to the replset
      alive_hosts = alive_members(@property_flush[:members])
      raise Puppet::Error, "Can't connect to any member of replicaset #{self.name}." if alive_hosts.empty?
      dead_hosts  = @property_flush[:members] - alive_hosts
      Puppet.debug "Alive members: #{alive_hosts.inspect}"
      Puppet.debug "Dead members: #{dead_hosts.inspect}" unless dead_hosts.empty?
    else
      alive_hosts = []
    end
    alive_hosts
  end

  def set_members
    if @property_flush[:ensure] == :absent
      # TODO: I don't know how to remove a node from a replset; unimplemented
      #Puppet.debug "Removing all members from replset #{self.name}"
      #@property_hash[:members].collect do |member|
      #  rs_remove(member, master_host(@property_hash[:members]))
      #end
      return
    end

    if primary?(alive_hosts)
      # Add members to an existing replset
      alive = alive_members(@property_flush[:members])
      if master = master_host(alive)
        current_hosts = db_ismaster(master)['hosts']
        newhosts = alive - current_hosts
        newhosts.each do |host|
          output = rs_add(host, master)
          if output['ok'] == 0
            raise Puppet::Error, "rs.add() failed to add host to replicaset #{self.name}: #{output['errmsg']}"
          end
        end
      else
        raise Puppet::Error, "Can't find master host for replicaset #{self.name}."
      end
    else
      if (@property_flush[:ensure] == :present) && (@property_hash[:ensure] != :present)
        Puppet.debug "Initializing the replset #{self.name}"
        # Create a replset configuration
        alive = alive_hosts
        hostconf = alive.each_with_index.map do |host,id|
          "{ _id: #{id}, host: '#{host}'}"
        end.join(',')
        conf = "{ _id: '#{self.name}', members: [ #{hostconf} ] }"

        # Set replset members with the first host as the master
        master = alive[0]
        output = rs_initiate(conf, master)
        if output['ok'] == 0
          raise Puppet::Error, "rs.initiate() failed for replicaset #{self.name}: #{output['errmsg']}"
        end
        # Wait till the end of initialization
        retry_count = 10
        retry_sleep = 3
        retry_count.times do |n|
          begin
            state = mongo_command('rs.status()', master)['members'][0]['stateStr']
          rescue Exception => e
            Puppet.debug "Replica set master is #{master} and it's not started yet. Retry: #{n}"
            sleep retry_sleep
            next
          end
          if state == 'PRIMARY'
            Puppet.debug "Replica set master is #{master} and it has successfully started"
            return
          end
        end
      end
    end
  end

  def self.get_bind_ips
    config = get_mongod_conf_file
    if mongo_24?
      split_string = /\s*=\s*/
      bind_key = 'bind_ip'
    else
      split_string = /\s*:\s*/
      bind_key = 'net.bindIp'
    end
    File.open(get_mongod_conf_file) do |fp|
      fp.each do |line|
        if !line.start_with?('#')
          key, value = line.chomp.split(split_string)
          if key == bind_key
            return value.split(',')
          end
        end
      end
    end
  end

  def mongo_command(command, host, retries=4)
    self.class.mongo_command(command,host,retries, auth_enabled)
  end

  def self.mongo_command(command, host=nil, retries=4, auth_enabled=false)
    if host
      ip = host.include?(':') ?  host.split(':')[0] : host
      if auth_enabled and get_bind_ips.include? ip
        # We can't setup replica from any hosts except localhost
        # if authentication is enabled and users aren't exist
        # User can't be created before replica set initialization
        # So we can't use user credentials for auth
        host = '127.0.0.1'
      end
    end
    # Allow waiting for mongod to become ready
    # Wait for 2 seconds initially and double the delay at each retry
    wait = 2
    begin
      args = Array.new
      args << '--quiet'
      if host
        args << ['--host',host]
        # Load authorization before each command
        raise Puppet::Error, '/root/.mongorc.js is not exist' unless File.exist?('/root/.mongorc.js')
        printjson = "load('/root/.mongorc.js'); printjson(#{command})" if host
      else
        printjson ||= "printjson(#{command})"
      end
      args << ['--eval', printjson ]
      output = mongo(args.flatten)
    rescue Puppet::ExecutionFailure => e
      if e =~ /Error: couldn't connect to server/ and wait <= 2**max_wait
        info("Waiting #{wait} seconds for mongod to become available")
        sleep wait
        wait *= 2
        retry
      else
        raise
      end
    end

    # Dirty hack to remove JavaScript objects
    output.gsub!(/ISODate\((.+?)\)/, '\1 ')
    output.gsub!(/Timestamp\((.+?)\)/, '[\1]')
    output.gsub!(/ObjectId\((.+?)\)/, '[\1]')
    output.gsub!(/^Error\:.+/, '')

    #Hack to avoid non-json empty sets
    output = '{}' if output == "null\n"

    JSON.parse(output)
  end

end
