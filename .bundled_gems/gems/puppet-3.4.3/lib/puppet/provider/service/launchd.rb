require 'facter/util/plist'
Puppet::Type.type(:service).provide :launchd, :parent => :base do
  desc <<-'EOT'
    This provider manages jobs with `launchd`, which is the default service
    framework for Mac OS X (and may be available for use on other platforms).

    For `launchd` documentation, see:

    * <http://developer.apple.com/macosx/launchd.html>
    * <http://launchd.macosforge.org/>

    This provider reads plists out of the following directories:

    * `/System/Library/LaunchDaemons`
    * `/System/Library/LaunchAgents`
    * `/Library/LaunchDaemons`
    * `/Library/LaunchAgents`

    ...and builds up a list of services based upon each plist's "Label" entry.

    This provider supports:

    * ensure => running/stopped,
    * enable => true/false
    * status
    * restart

    Here is how the Puppet states correspond to `launchd` states:

    * stopped --- job unloaded
    * started --- job loaded
    * enabled --- 'Disable' removed from job plist file
    * disabled --- 'Disable' added to job plist file

    Note that this allows you to do something `launchctl` can't do, which is to
    be in a state of "stopped/enabled" or "running/disabled".

    Note that this provider does not support overriding 'restart' or 'status'.

  EOT

  include Puppet::Util::Warnings

  commands :launchctl => "/bin/launchctl"
  commands :sw_vers   => "/usr/bin/sw_vers"
  commands :plutil    => "/usr/bin/plutil"

  defaultfor :operatingsystem => :darwin
  confine :operatingsystem    => :darwin

  has_feature :enableable
  has_feature :refreshable
  mk_resource_methods

  # These are the paths in OS X where a launchd service plist could
  # exist. This is a helper method, versus a constant, for easy testing
  # and mocking
  #
  # @api private
  def self.launchd_paths
    [
      "/Library/LaunchAgents",
      "/Library/LaunchDaemons",
      "/System/Library/LaunchAgents",
      "/System/Library/LaunchDaemons"
    ]
  end

  # Defines the path to the overrides plist file where service enabling
  # behavior is defined in 10.6 and greater.
  #
  # @api private
  def self.launchd_overrides
    "/var/db/launchd.db/com.apple.launchd/overrides.plist"
  end

  # Caching is enabled through the following three methods. Self.prefetch will
  # call self.instances to create an instance for each service. Self.flush will
  # clear out our cache when we're done.
  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  # Self.instances will return an array with each element being a hash
  # containing the name, provider, path, and status of each service on the
  # system.
  def self.instances
    jobs = self.jobsearch
    @job_list ||= self.job_list
    jobs.keys.collect do |job|
      job_status = @job_list.has_key?(job) ? :running : :stopped
      new(:name => job, :provider => :launchd, :path => jobs[job], :status => job_status)
    end
  end

  # This method will return a list of files in the passed directory. This method
  # does not go recursively down the tree and does not return directories
  #
  # @param path [String] The directory to glob
  #
  # @api private
  #
  # @return [Array] of String instances modeling file paths
  def self.return_globbed_list_of_file_paths(path)
    array_of_files = Dir.glob(File.join(path, '*')).collect do |filepath|
      File.file?(filepath) ? filepath : nil
    end
    array_of_files.compact
  end

  # Get a hash of all launchd plists, keyed by label.  This value is cached, but
  # the cache will be refreshed if refresh is true.
  #
  # @api private
  def self.make_label_to_path_map(refresh=false)
    return @label_to_path_map if @label_to_path_map and not refresh
    @label_to_path_map = {}
    launchd_paths.each do |path|
      return_globbed_list_of_file_paths(path).each do |filepath|
        job = read_plist(filepath)
        next if job.nil?
        if job.has_key?("Label")
          @label_to_path_map[job["Label"]] = filepath
        else
          Puppet.warning("The #{filepath} plist does not contain a 'label' key; " +
                       "Puppet is skipping it")
          next
        end
      end
    end
    @label_to_path_map
  end

  # Sets a class instance variable with a hash of all launchd plist files that
  # are found on the system. The key of the hash is the job id and the value
  # is the path to the file. If a label is passed, we return the job id and
  # path for that specific job.
  def self.jobsearch(label=nil)
    by_label = make_label_to_path_map

    if label
      if by_label.has_key? label
        return { label => by_label[label] }
      else
        # try refreshing the map, in case a plist has been added in the interim
        by_label = make_label_to_path_map(true)
        if by_label.has_key? label
          return { label => by_label[label] }
        else
          raise Puppet::Error, "Unable to find launchd plist for job: #{label}"
        end
      end
    else
      # caller wants the whole map
      by_label
    end
  end

  # This status method lists out all currently running services.
  # This hash is returned at the end of the method.
  def self.job_list
    @job_list = Hash.new
    begin
      output = launchctl :list
      raise Puppet::Error.new("launchctl list failed to return any data.") if output.nil?
      output.split("\n").each do |line|
        @job_list[line.split(/\s/).last] = :running
      end
    rescue Puppet::ExecutionFailure
      raise Puppet::Error.new("Unable to determine status of #{resource[:name]}")
    end
    @job_list
  end

  # Launchd implemented plist overrides in version 10.6.
  # This method checks the major_version of OS X and returns true if
  # it is 10.6 or greater. This allows us to implement different plist
  # behavior for versions >= 10.6
  def has_macosx_plist_overrides?
    @product_version ||= self.class.get_macosx_version_major
    # (#11593) Remove support for OS X 10.4 & earlier
    # leaving this as is because 10.5 still didn't have plist support
    return true unless /^10\.[0-5]/.match(@product_version)
    return false
  end

  # Read a plist, whether its format is XML or in Apple's "binary1"
  # format.
  def self.read_plist(path)
    begin
      Plist::parse_xml(plutil('-convert', 'xml1', '-o', '/dev/stdout', path))
    rescue Puppet::ExecutionFailure => detail
      Puppet.warning("Cannot read file #{path}; Puppet is skipping it. \n" +
                     "Details: #{detail}")
      return nil
    end
  end

  # Clean out the @property_hash variable containing the cached list of services
  def flush
    @property_hash.clear
  end

  def exists?
    Puppet.debug("Puppet::Provider::Launchd:Ensure for #{@property_hash[:name]}: #{@property_hash[:ensure]}")
    @property_hash[:ensure] != :absent
  end

  def self.get_macosx_version_major
    return @macosx_version_major if @macosx_version_major
    begin
      # Make sure we've loaded all of the facts
      Facter.loadfacts

      product_version_major = Facter.value(:macosx_productversion_major)

      fail("#{product_version_major} is not supported by the launchd provider") if %w{10.0 10.1 10.2 10.3 10.4}.include?(product_version_major)
      @macosx_version_major = product_version_major
      return @macosx_version_major
    rescue Puppet::ExecutionFailure => detail
      fail("Could not determine OS X version: #{detail}")
    end
  end


  # finds the path for a given label and returns the path and parsed plist
  # as an array of [path, plist]. Note plist is really a Hash here.
  def plist_from_label(label)
    job = self.class.jobsearch(label)
    job_path = job[label]
    if FileTest.file?(job_path)
      job_plist = self.class.read_plist(job_path)
    else
      raise Puppet::Error.new("Unable to parse launchd plist at path: #{job_path}")
    end
    [job_path, job_plist]
  end

  # start the service. To get to a state of running/enabled, we need to
  # conditionally enable at load, then disable by modifying the plist file
  # directly.
  def start
    return ucommand(:start) if resource[:start]
    job_path, job_plist = plist_from_label(resource[:name])
    did_enable_job = false
    cmds = []
    cmds << :launchctl << :load
    if self.enabled? == :false  || self.status == :stopped # launchctl won't load disabled jobs
      cmds << "-w"
      did_enable_job = true
    end
    cmds << job_path
    begin
      execute(cmds)
    rescue Puppet::ExecutionFailure
      raise Puppet::Error.new("Unable to start service: #{resource[:name]} at path: #{job_path}")
    end
    # As load -w clears the Disabled flag, we need to add it in after
    self.disable if did_enable_job and resource[:enable] == :false
  end


  def stop
    return ucommand(:stop) if resource[:stop]
    job_path, job_plist = plist_from_label(resource[:name])
    did_disable_job = false
    cmds = []
    cmds << :launchctl << :unload
    if self.enabled? == :true # keepalive jobs can't be stopped without disabling
      cmds << "-w"
      did_disable_job = true
    end
    cmds << job_path
    begin
      execute(cmds)
    rescue Puppet::ExecutionFailure
      raise Puppet::Error.new("Unable to stop service: #{resource[:name]} at path: #{job_path}")
    end
    # As unload -w sets the Disabled flag, we need to add it in after
    self.enable if did_disable_job and resource[:enable] == :true
  end

  def restart
    Puppet.debug("A restart has been triggered for the #{resource[:name]} service")
    Puppet.debug("Stopping the #{resource[:name]} service")
    self.stop
    Puppet.debug("Starting the #{resource[:name]} service")
    self.start
  end

  # launchd jobs are enabled by default. They are only disabled if the key
  # "Disabled" is set to true, but it can also be set to false to enable it.
  # Starting in 10.6, the Disabled key in the job plist is consulted, but only
  # if there is no entry in the global overrides plist.  We need to draw a
  # distinction between undefined, true and false for both locations where the
  # Disabled flag can be defined.
  def enabled?
    job_plist_disabled = nil
    overrides_disabled = nil

    job_path, job_plist = plist_from_label(resource[:name])
    job_plist_disabled = job_plist["Disabled"] if job_plist.has_key?("Disabled")

    if has_macosx_plist_overrides?
      if FileTest.file?(self.class.launchd_overrides) and overrides = self.class.read_plist(self.class.launchd_overrides)
        if overrides.has_key?(resource[:name])
          overrides_disabled = overrides[resource[:name]]["Disabled"] if overrides[resource[:name]].has_key?("Disabled")
        end
      end
    end

    if overrides_disabled.nil?
      if job_plist_disabled.nil? or job_plist_disabled == false
        return :true
      end
    elsif overrides_disabled == false
      return :true
    end
    :false
  end

  # enable and disable are a bit hacky. We write out the plist with the appropriate value
  # rather than dealing with launchctl as it is unable to change the Disabled flag
  # without actually loading/unloading the job.
  # Starting in 10.6 we need to write out a disabled key to the global
  # overrides plist, in earlier versions this is stored in the job plist itself.
  def enable
    if has_macosx_plist_overrides?
      overrides = self.class.read_plist(self.class.launchd_overrides)
      overrides[resource[:name]] = { "Disabled" => false }
      Plist::Emit.save_plist(overrides, self.class.launchd_overrides)
    else
      job_path, job_plist = plist_from_label(resource[:name])
      if self.enabled? == :false
        job_plist.delete("Disabled")
        Plist::Emit.save_plist(job_plist, job_path)
      end
    end
  end

  def disable
    if has_macosx_plist_overrides?
      overrides = self.class.read_plist(self.class.launchd_overrides)
      overrides[resource[:name]] = { "Disabled" => true }
      Plist::Emit.save_plist(overrides, self.class.launchd_overrides)
    else
      job_path, job_plist = plist_from_label(resource[:name])
      job_plist["Disabled"] = true
      Plist::Emit.save_plist(job_plist, job_path)
    end
  end
end
