class Puppet::Provider::Pacemaker < Puppet::Provider

  # Yep, that's right we are parsing XML...FUN! (It really wasn't that bad)
  require 'rexml/document'

  initvars
  commands :pcs => 'pcs'

  def self.run_pcs_command(pcs_cmd, failonfail = true)
    if Puppet::PUPPETVERSION.to_f < 3.4
      raw, status = Puppet::Util::SUIDManager.run_and_capture(pcs_cmd)
    else
      raw = Puppet::Util::Execution.execute(pcs_cmd, {:failonfail => failonfail})
      status = raw.exitstatus
    end
    if status == 0 or failonfail == false
      return raw, status
    else
      fail("command #{pcs_cmd.join(" ")} failed")
    end
  end



  # Corosync takes a while to build the initial CIB configuration once the
  # service is started for the first time.  This provides us a way to wait
  # until we're up so we can make changes that don't disappear in to a black
  # hole.
  def self.ready?
    cmd =  [ command(:pcs), 'property', 'show', 'dc-version' ]
    raw, status = run_pcs_command(cmd, false)
    if status == 0
      return true
    else
      return false
    end
  end

  def self.block_until_ready(timeout = 120)
    Timeout::timeout(timeout) do
      until ready?
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
    debug(@property_hash.inspect)
    !(@property_hash[:ensure] == :absent or @property_hash.empty?)
  end
end
