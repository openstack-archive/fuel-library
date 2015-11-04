 'puppet/provider/package/apt'
require 'fcntl'

Puppet::Type.type(:package).provide :apt_fuel, :parent => :apt, :source => :apt do

  desc "Package management via `apt-get` managing locks."

  has_feature :versionable

  defaultfor :operatingsystem => [:ubuntu]

  def locked?(file)
    """
    Check whether ``apt-get`` or ``dpkg`` is currently active.

    This works by checking whether the lock file ``/var/lib/dpkg/lock`` is
    locked by an ``apt-get`` or ``dpkg`` process, which in turn is done by
    momentarily trying to acquire the lock. This means that the current process
    needs to have sufficient privileges.
    """
    f = open(file, 'w')
    flockstruct = [Fcntl::F_RDLCK, 0, 0, 0, 0].pack("ssqqi")
    f.fcntl Fcntl::F_GETLK, flockstruct
    status =  flockstruct.unpack("ssqqi")[0]
    case status
      when Fcntl::F_UNLCK
        return false 
      when Fcntl::F_WRLCK|Fcntl::F_RDLCK
        return true
      else
        raise SystemCallError, status
    f.close()
  end

  end

  def wait_for_lock
    default_timeout = 300
    lock_file = '/var/lib/dpkg/lock'
    time_started = Time.now.getutc.to_i
    wait_for = @property_hash.key?(:timeout) ? @property_hash[:timeout] : default_timeout

    debug("Checking if dpkg lock is released")
    while (Time.now.getutc.to_i < time_started + wait_for) and self.locked?(lock_file)
      sleep(5)
    end

    if self.locked?(lock_file)
      raise Puppet::Error, "dpkg [#{lock_file}] is locked by another process."
    end
  end

  def install
    self.wait_for_lock()
    super
  end

  def uninstall
    self.wait_for_lock()
    super
  end

  def purge
    self.wait_for_lock()
    super
  end
end
