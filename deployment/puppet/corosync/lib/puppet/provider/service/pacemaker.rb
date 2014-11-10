require File.join File.dirname(__FILE__), '../pacemaker_common.rb'

Puppet::Type.type(:service).provide :pacemaker, :parent => Puppet::Provider::Pacemaker_common do

  has_feature :enableable
  has_feature :refreshable

  # how do we determine that the service have been started?
  # :global - The service is running on any node
  # :master - The service is running in the master mode on any node
  # :local  - The service is running on the local node
  START_MODE_MULTISTATE = :master
  START_MODE_CLONE      = :global
  START_MODE_SIMPLE     = :global

  # what method should be used to stop the service?
  # :global - Stop the running service by disabling it
  # :local  - Stop the locally running service by banning it on this node
  # Note: by default restart does not stop services
  # if they are not running locally on the node
  STOP_MODE_MULTISTATE = :local
  STOP_MODE_CLONE      = :local
  STOP_MODE_SIMPLE     = :global

  # what service is considered running?
  # :global - The service is running on any node
  # :local  - The service is running on the local node
  STATUS_MODE_MULTISTATE = :local
  STATUS_MODE_CLONE      = :local
  STATUS_MODE_SIMPLE     = :local

  # try to stop and disable the basic init/upstart service
  DISABLE_BASIC_SERVICE   = true
  # add location constraint to allow the service on the current node
  # useful for asymmetric cluster mode
  ADD_LOCATION_CONSTRAINT = true
  # restart the service only if it's running on this node
  # and skip restart if it's running elsewhere
  RESTART_ONLY_IF_LOCAL   = true

  # cleanup the primitive before the status action.
  CLEANUP_ON_STATUS = false
  # cleanup the primitive before the start action
  CLEANUP_ON_START  = true
  # cleanup the primitive before the stop action
  CLEANUP_ON_STOP   = true

  commands :crm_node      => 'crm_node'
  commands :crm_resource  => 'crm_resource'
  commands :crm_attribute => 'crm_attribute'
  commands :cibadmin      => 'cibadmin'

  # hostname of the current node
  # @return [String]
  def hostname
    return @hostname if @hostname
    @hostname = (crm_node '-n').chomp.strip
  end

  # original name passed from the type
  # @return [String]
  def title
    @resource[:name]
  end

  # primitive name with 'p_' added if needed
  # @return [String]
  def name
    return @name if @name
    primitive_name = title
    if primitive_exists? primitive_name
      debug "Primitive with title '#{primitive_name}' was found in CIB"
      @name = primitive_name
      return @name
    end
    primitive_name = "p_#{title}"
    if primitive_exists? primitive_name
      debug "Using '#{primitive_name}' name instead of '#{title}'"
      @name = primitive_name
      return @name
    end
    primitive_name = title.gsub /(ms-)|(clone-)/, ''
    if primitive_exists? primitive_name
      debug "Using simple name '#{primitive_name}' instead of '#{title}'"
      @name = primitive_name
      return @name
    end
    fail "Primitive '#{title}' was not found in CIB!"
  end

  # full name of the primitive
  # if resource is complex use group name
  # @return [String]
  def full_name
    return @full_name if @full_name
    if primitive_is_complex? name
      full_name = primitives[name]['name']
      debug "Using full name '#{full_name}' for complex primitive '#{name}'"
      @full_name = full_name
    else
      @full_name = name
    end
  end

  # name of the basic service without 'p_' prefix
  # used to disable the basic service
  # @return [String]
  def basic_service_name
    return @basic_service_name if @basic_service_name
    if name.start_with? 'p_'
      basic_service_name = name.gsub /^p_/, ''
      debug "Using '#{basic_service_name}' as the basic service name for primitive '#{name}'"
      @basic_service_name = basic_service_name
    else
      @basic_service_name = name
    end
  end

  # called by Puppet to determine if the service
  # is running on the local node
  # @return [:running,:stopped]
  def status
    wait_for_online
    debug "Call: 'status' for Pacemaker service '#{name}' on node '#{hostname}'"
    cib_reset
    cleanup_with_wait name, hostname if CLEANUP_ON_STATUS and primitive_has_failures? name, hostname
    if primitive_is_multistate? name
      out = service_status_mode STATUS_MODE_MULTISTATE
    elsif primitive_is_clone? name
      out = service_status_mode STATUS_MODE_CLONE
    else
      out = service_status_mode STATUS_MODE_SIMPLE
    end
    debug "Return: '#{out}' (#{out.class})"
    debug cluster_debug_report "#{@resource} status"
    out
  end

  # called by Puppet to start the service
  def start
    debug "Call 'start' for Pacemaker service '#{name}' on node '#{hostname}'"
    enable unless primitive_is_managed? name
    disable_basic_service if DISABLE_BASIC_SERVICE
    constraint_location_add name, hostname if ADD_LOCATION_CONSTRAINT
    unban_primitive name, hostname
    start_primitive name
    cleanup_with_wait name, hostname if CLEANUP_ON_START and primitive_has_failures? name, hostname

    if primitive_is_multistate? name
      debug "Choose master start for Pacemaker service '#{name}'"
      wait_for_master name
    else
      service_start_mode START_MODE_SIMPLE
    end
    debug cluster_debug_report "#{@resource} start"
  end

  # called by Puppet to stop the service
  def stop
    debug "Call 'stop' for Pacemaker service '#{name}' on node '#{hostname}'"
    enable unless primitive_is_managed? name
    cleanup_with_wait name, hostname if CLEANUP_ON_STOP and primitive_has_failures? name, hostname

    if primitive_is_multistate? name
      service_stop_mode STOP_MODE_MULTISTATE
    elsif primitive_is_clone? name
      service_stop_mode STOP_MODE_CLONE
    else
      service_stop_mode STOP_MODE_SIMPLE
    end
    debug cluster_debug_report "#{@resource} stop"
  end

  # called by Puppet to restart the service
  def restart
    debug "Call 'restart' for Pacemaker service '#{name}' on node '#{hostname}'"
    if RESTART_ONLY_IF_LOCAL and not primitive_is_running? name, hostname
      Puppet.info "Pacemaker service '#{name}' is not running on node '#{hostname}'. Skipping restart!"
      return
    end

    begin
      stop
    rescue
      nil
    ensure
      start
    end
  end

  # wait for the service to start using
  # the selected method.
  # @param mode [:global, :master, :local]
  def service_start_mode(mode = :global)
    if mode == :master
      debug "Choose master start for Pacemaker service '#{name}'"
      wait_for_master name
    elsif mode == :local
      debug "Choose local start for Pacemaker service '#{name}' on node '#{hostname}'"
      wait_for_start name, hostname
    elsif :global
      debug "Choose global start for Pacemaker service '#{name}'"
      wait_for_start name
    else
      fail "Unknown service start mode '#{mode}'"
    end
  end

  # wait for the service to stop using
  # the selected method.
  # @param mode [:global, :master, :local]
  def service_stop_mode(mode = :global)
    if mode == :local
      debug "Choose local stop for Pacemaker service '#{name}' on node '#{hostname}'"
      ban_primitive name, hostname
      wait_for_stop name, hostname
    elsif mode == :global
      debug "Choose global stop for Pacemaker service '#{name}'"
      stop_primitive name
      wait_for_stop name
    else
      fail "Unknown service stop mode '#{mode}'"
    end
  end

  # determine the status of the service using
  # the selected method.
  # @param mode [:global, :master, :local]
  # @return [:running,:stopped]
  def service_status_mode(mode = :local)
    if mode == :local
      debug "Choose local status for Pacemaker service '#{name}' on node '#{hostname}'"
      get_primitive_puppet_status name, hostname
    elsif mode == :global
      debug "Choose global status for Pacemaker service '#{name}'"
      get_primitive_puppet_status name
    else
      fail "Unknown service status mode '#{mode}'"
    end
  end

  # called by Puppet to enable the service
  def enable
    debug "Call 'enable' for Pacemaker service '#{name}' on node '#{hostname}'"
    manage_primitive name
  end

  # called by Puppet to disable  the service
  def disable
    debug "Call 'disable' for Pacemaker service '#{name}' on node '#{hostname}'"
    unmanage_primitive name
  end

  alias :manual_start :disable

  # called by Puppet to determine if the service is enabled
  # @return [:true,:false]
  def enabled?
    debug "Call 'enabled?' for Pacemaker service '#{name}' on node '#{hostname}'"
    out = get_primitive_puppet_enable name
    debug "Return: '#{out}' (#{out.class})"
    out
  end

  # create an extra provider instance to deal with the basic service
  # the provider will be chosen to match the current system
  # @return [Puppet::Type::Service::Provider]
  def extra_provider(provider_name = nil)
    return @extra_provider if @extra_provider
    begin
      param_hash = {}
      param_hash.store :name, basic_service_name
      param_hash.store :provider, provider_name if provider_name
      type = Puppet::Type::Service.new param_hash
      @extra_provider = type.provider
    rescue => e
      Puppet.warning "Could not get extra provider for Pacemaker primitive '#{name}': #{e.message}"
      @extra_provider = nil
    end
  end

  # disable and stop the basic service
  def disable_basic_service
    return unless extra_provider
    begin
      if extra_provider.enableable? and extra_provider.enabled? == :true
        Puppet.info "Disable basic service '#{extra_provider.name}' using provider '#{extra_provider.class.name}'"
        extra_provider.disable
      else
        Puppet.info "Basic service '#{extra_provider.name}' is disabled as reported by '#{extra_provider.class.name}' provider"
      end
      if extra_provider.status == :running
        Puppet.info "Stop basic service '#{extra_provider.name}' using provider '#{extra_provider.class.name}'"
        extra_provider.stop
      else
        Puppet.info "Basic service '#{extra_provider.name}' is stopped as reported by '#{extra_provider.class.name}' provider"
      end
    rescue => e
      Puppet.warning "Could not disable basic service for Pacemaker primitive '#{name}' using '#{extra_provider.class.name}' provider: #{e.message}"
    end
  end

end
