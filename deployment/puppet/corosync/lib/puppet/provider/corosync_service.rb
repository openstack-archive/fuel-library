class Puppet::Provider::Corosync_service < Puppet::Provider
  require "open3"
  # Yep, that's right we are parsing XML...FUN! (It really wasn't that bad)
  require 'rexml/document'
  #require 'system'


  def self.dump_cib
    self.block_until_ready
    stdout = Open3.popen3("#{command(:cibadmin)} -Q")[1].read
    return stdout, nil
  end

  def try_command(command,resource_name,should=nil,cib=nil,timeout=120)
    cmd = "#{command(:crm)} configure #{command} #{resource_name} #{should} ".rstrip
    env = {}
      if cib
        env["CIB_shadow"]=cib.to_s
      end
    Timeout::timeout(timeout) do
      debug("Issuing  #{cmd} for CIB #{cib}  ")
      loop do
        break  if exec_withenv(cmd,env) == 0
        sleep 2
      end
    end
  end

  def exec_withenv(cmd,env=nil)
    self.class.exec_withenv(cmd,env)
  end

  def self.exec_withenv(cmd,env=nil)
    Process.fork  do
      ENV.update(env) if !env.nil?
      Process.exec(cmd)
    end
    Process.wait
    $?.exitstatus
  end

  # Corosync takes a while to build the initial CIB configuration once the
  # service is started for the first time.  This provides us a way to wait
  # until we're up so we can make changes that don't disappear in to a black
  # hole.

  def self.block_until_ready(timeout = 120)
    cmd = "#{command(:crm_attribute)} --type crm_config --query --name dc-version 2>/dev/null"
    Timeout::timeout(timeout) do
      until exec_withenv(cmd) == 0
        debug('Corosync not ready, retrying')
        sleep 2
      end
      # Sleeping a spare two since it seems that dc-version is returning before
      # It is really ready to take config changes, but it is close enough.
      # Probably need to find a better way to check for reediness.
      sleep 2
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if res = resources[prov.name.to_s]
        res.provider = prov
      end
    end
  end

  def exists?
    self.class.block_until_ready
    #debug(@property_hash.inspect)
    !(@property_hash[:ensure] == :absent or @property_hash.empty?)
  end
end
