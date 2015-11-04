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
    wait_for = @property_hash.key?(:timeout) ? @property_hash[:timeout] : default_timeout

    Timeout::timeout(wait_for,Puppet::Error) do
      while self.locked?(lock_file) do
        debug("#{lock_file} is locked, retrying")
        sleep 2
      end
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
