require 'fcntl'

Puppet::Type.type(:package).provide :apt_fuel, :parent => :apt, :source => :apt do

  desc "Package management via `apt-get` managing locks."

  has_feature :versionable
  has_feature :install_options

  defaultfor :operatingsystem => [:ubuntu]

  attr_accessor :default_lock_timeout,
                :lock_file,
                :lock_sleep,
                :retry_count,
                :retry_sleep

  def initialize(value={})
    super(value)
    @default_lock_timeout = 300
    @lock_file = '/var/lib/dpkg/lock'
    @lock_sleep = 2
    @retry_count = 3
    @retry_sleep = 5
  end

  def timeout
    @property_hash.fetch(:timeout, @default_lock_timeout)
  end

  # Check whether ``apt-get`` or ``dpkg`` is currently active.
  #
  # This works by checking whether the lock file ``/var/lib/dpkg/lock`` is
  # locked by an ``apt-get`` or ``dpkg`` process, which in turn is done by
  # momentarily trying to acquire the lock. This means that the current process
  # needs to have sufficient privileges.
  # @return [true,false]
  def locked?(file)
    debug 'Call: locked?'
    status = open(file, 'w') do |lock|
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
  # @yields block when there is no lock
  def wait_for_lock
    debug 'Call: wait_for_lock'
    Timeout::timeout(timeout, Timeout::Error) do
      while locked? @lock_file do
        debug "#{@lock_file} is locked, retrying..."
        sleep @lock_sleep
      end
    end
    yield
  end

  def install
    debug 'Call: install'
    @resource[:install_options] = ['-o', 'APT::Get::AllowUnauthenticated=1']
    (1..@retry_count).each do |try|
      begin
        wait_for_lock do
          super
        end
        info "Attempt '#{try}' of '#{@retry_count}' was successful!" if try > 1
        break
      rescue Puppet::ExecutionFailure, Timeout::Error => exception
        warning "Attempt '#{try}' of '#{@retry_count}' has failed: #{exception.message}"
        raise exception if try >= @retry_count
        sleep @retry_sleep
        apt_get_update
      end
    end
  end

  def apt_get_update
    debug 'Call: apt_get_update'
    wait_for_lock do
      aptget '-q', '-y', :update
    end
  end

  def uninstall
    debug 'Call: uninstall'
    wait_for_lock do
      super
    end
  end

  def purge
    debug 'Call: purge'
    wait_for_lock do
      super
    end
  end
end
