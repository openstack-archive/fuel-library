require 'fcntl'

Puppet::Type.type(:package).provide :apt_fuel, :parent => :apt, :source => :apt do

  desc "Package management via `apt-get` managing locks."

  has_feature :versionable

  defaultfor :operatingsystem => [:ubuntu]

  def default_lock_timeout
    300
  end

  def lock_file
    '/var/lib/dpkg/lock'
  end

  def lock_sleep
    2
  end

  def retry_count
    3
  end

  def retry_sleep
    5
  end

  # Check whether ``apt-get`` or ``dpkg`` is currently active.
  #
  # This works by checking whether the lock file ``/var/lib/dpkg/lock`` is
  # locked by an ``apt-get`` or ``dpkg`` process, which in turn is done by
  # momentarily trying to acquire the lock. This means that the current process
  # needs to have sufficient privileges.
  # @return [true,false]
  def locked?
    status = open(lock_file, 'w') do |lock|
      flock_struct = [Fcntl::F_RDLCK, 0, 0, 0, 0].pack('ssqqi')
      lock.fcntl Fcntl::F_GETLK, flock_struct
      flock_struct.unpack('ssqqi').first
    end
    case status
      when Fcntl::F_UNLCK
        return false
      when Fcntl::F_WRLCK|Fcntl::F_RDLCK
        return true
      else
        raise SystemCallError, status
    end
  end

  # Wait for the lock file to be unlocked
  # and the ``dpkg`` not being currently active.
  def wait_for_lock
    timeout = @property_hash.fetch(:timeout, default_lock_timeout)
    Timeout::timeout(timeout, Puppet::Error) do
      while locked? do
        debug "#{lock_file} is locked, retrying..."
        sleep lock_sleep
      end
    end
  end

  def install
    (1..retry_count).each do |try|
      begin
        wait_for_lock
        super
        info "Attempt #{try} of #{retry_count} was successful!" if try > 1
        break
      rescue Puppet::ExecutionFailure => exception
        warning "Attempt #{try} of #{retry_count} have failed: #{exception.message}"
        raise exception if try == retry_count
        sleep retry_sleep
        update
      end
    end
  end

  def update
    wait_for_lock
    aptget :update
  end

  def uninstall
    wait_for_lock
    super
  end

  def purge
    wait_for_lock
    super
  end
end
