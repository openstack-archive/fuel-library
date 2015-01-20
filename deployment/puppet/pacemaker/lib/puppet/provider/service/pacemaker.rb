require File.join File.dirname(__FILE__), '../pacemaker_common.rb'

Puppet::Type.type(:service).provide :pacemaker, :parent => Puppet::Provider::Pacemaker_common do

  has_feature :enableable
  has_feature :refreshable

  commands :uname => 'uname'
  commands :pcs => 'pcs'
  commands :crm_resource => 'crm_resource'
  commands :crm_attribute => 'crm_attribute'
  commands :cibadmin => 'cibadmin'

  # hostname of the current node
  # @return [String]
  def hostname
    return @hostname if @hostname
    @hostname = (uname '-n').chomp.strip
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
      Puppet.debug "Primitive with title '#{primitive_name}' was found in CIB"
      @name = primitive_name
      return @name
    end
    primitive_name = "p_#{primitive_name}"
    if primitive_exists? primitive_name
      Puppet.debug "Using '#{primitive_name}' name instead of '#{title}'"
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
      Puppet.debug "Using full name '#{full_name}' for complex primitive '#{name}'"
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
      Puppet.debug "Using '#{basic_service_name}' as the basic service name for primitive '#{name}'"
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
    Puppet.debug "Call: 'status' for Pacemaker service '#{name}' on node '#{hostname}'"
    cib_reset
    out = get_primitive_puppet_status name, hostname
    Puppet.debug get_cluster_debug_report
    Puppet.debug "Return: '#{out}' (#{out.class})"
    out
  end

  # called by Puppet to start the service
  def start
    Puppet.debug "Call 'start' for Pacemaker service '#{name}' on node '#{hostname}'"
    enable unless primitive_is_managed? name
    disable_basic_service
    constraint_location_add name, hostname
    unban_primitive name, hostname
    start_primitive name
    cleanup_with_wait(name, hostname) if primitive_has_failures?(name, hostname)

    if primitive_is_multistate? name
      Puppet.debug "Choose master start for Pacemaker service '#{name}'"
      wait_for_master name
    else
      Puppet.debug "Choose global start for Pacemaker service '#{name}'"
      wait_for_start name
    end
  end

  # called by Puppet to stop the service
  def stop
    Puppet.debug "Call 'stop' for Pacemaker service '#{name}' on node '#{hostname}'"
    enable unless primitive_is_managed? name
    cleanup_with_wait(name, hostname) if primitive_has_failures?(name, hostname)

    if primitive_is_complex? name
      Puppet.debug "Choose local stop for Pacemaker service '#{name}' on node '#{hostname}'"
      ban_primitive name, hostname
      wait_for_stop name, hostname
    else
      Puppet.debug "Choose global stop for Pacemaker service '#{name}'"
      stop_primitive name
      wait_for_stop name
    end
  end

  # called by Puppet to restart the service
  def restart
    Puppet.debug "Call 'restart' for Pacemaker service '#{name}' on node '#{hostname}'"
    unless primitive_is_running? name, hostname
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

  # called by Puppet to enable the service
  def enable
    Puppet.debug "Call 'enable' for Pacemaker service '#{name}' on node '#{hostname}'"
    manage_primitive name
  end

  # called by Puppet to disable  the service
  def disable
    Puppet.debug "Call 'disable' for Pacemaker service '#{name}' on node '#{hostname}'"
    unmanage_primitive name
  end
  alias :manual_start :disable

  # called by Puppet to determine if the service is enabled
  # @return [:true,:false]
  def enabled?
    Puppet.debug "Call 'enabled?' for Pacemaker service '#{name}' on node '#{hostname}'"
    out = get_primitive_puppet_enable name
    Puppet.debug "Return: '#{out}' (#{out.class})"
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
