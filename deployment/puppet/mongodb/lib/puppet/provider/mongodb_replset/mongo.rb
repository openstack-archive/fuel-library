#
# Author: François Charlier <francois.charlier@enovance.com>
#

require 'json'

Puppet::Type.type(:mongodb_replset).provide(:mongo) do

  desc "Manage hosts members for a replicaset."

  commands :mongo => 'mongo'

  def create
    alive_members = members_present
    hostsconf = alive_members.collect.each_with_index do |host, id|
      "{ _id: #{id}, host: \"#{host}\" }"
    end.join(',')
    conf = "{ _id: \"#{@resource[:name]}\", members: [ #{hostsconf} ] }"
    output = self.rs_initiate(conf, alive_members[0])
    if output['ok'] == 0
      raise Puppet::Error, "rs.initiate() failed for replicaset #{@resource[:name]}: #{output['errmsg']}"
    end
  end

  def destroy
  end

  def exists?
    failcount = 0
    is_configured = false
    @resource[:members].each do |host|
      begin
        debug "Checking replicaset member #{host} ..."
        status = self.rs_status(host)
        if status.has_key?('errmsg') and status['errmsg'] == 'not running with --replSet'
            raise Puppet::Error, "Can't configure replicaset #{@resource[:name]}, host #{host} is not supposed to be part of a replicaset."
        end
        if status.has_key?('set')
          if status['set'] != @resource[:name]
            raise Puppet::Error, "Can't configure replicaset #{@resource[:name]}, host #{host} is already part of another replicaset."
          end
          is_configured = true
        end
      rescue Puppet::ExecutionFailure
        debug "Can't connect to replicaset member #{host}."
        failcount += 1
      end
    end

    if failcount == @resource[:members].length
      raise Puppet::Error, "Can't connect to any member of replicaset #{@resource[:name]}."
    end
    return is_configured
  end

  def members
    if master = self.master_host()
      self.db_ismaster(master)['hosts']
    else
      raise Puppet::Error, "Can't find master host for replicaset #{@resource[:name]}."
    end
  end

  def members=(hosts)
    if master = master_host()
      current = self.db_ismaster(master)['hosts']
      newhosts = hosts - current
      newhosts.each do |host|
        #TODO: check output (['ok'] == 0 should be sufficient)
        self.rs_add(host, master)
      end
    else
      raise Puppet::Error, "Can't find master host for replicaset #{@resource[:name]}."
    end
  end

  def members_present
    @resource[:members].select do |host|
      begin
        self.mongo('--host', host, '--quiet', '--eval', 'db.version()')
        true
      rescue Puppet::ExecutionFailure
        false
      end
    end
  end

  def mongo_command(command, host, retries=4)
    # Allow waiting for mongod to become ready
    # Wait for 2 seconds initially and double the delay at each retry
    wait = 2
    begin
      output = self.mongo('--quiet', '--host', host, '--eval', "printjson(#{command})")
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
    JSON.parse(output)
  end

  def master_host
    @resource[:members].each do |host|
      status = self.db_ismaster(host)
      if status.has_key?('primary')
        return status['primary']
      end
    end
    false
  end

  def db_ismaster(host)
    self.mongo_command("db.isMaster()", host)
  end

  def rs_initiate(conf, host)
    return self.mongo_command("rs.initiate(#{conf})", @resource[:members][0])

  end

  def rs_status(host)
    self.mongo_command("rs.status()", host)
  end

  def rs_add(host, master)
    self.mongo_command("rs.add(\"#{host}\")", master)
  end

end
