require File.join File.dirname(__FILE__), '../pacemaker.rb'

Puppet::Type.type(:service).provide :pacemaker, :parent => Puppet::Provider do
  include Pacemaker

  has_feature :enableable
  has_feature :refreshable

  commands :uname => 'uname'
  commands :pcs => 'pcs'
  commands :cibadmin => 'cibadmin'

  def hostname
    return @hostname if @hostname
    @hostname = (uname '-n').chomp.strip
  end

  # return primitive name or it's parent
  # name if resource is complex
  # @return [String]
  def full_name
    primitive_name = @resource[:name]
    raise "Primitive #{primitive_name} doesn't exist!" unless primitive_exists? primitive_name
    if primitive_is_complex? primitive_name
      primitive_name = primitives[primitive_name]['name']
    end
    primitive_name
  end

  # return original primitive name
  # @return [String]
  def name
    primitive_name = @resource[:name]
    raise "Primitive #{primitive_name} doesn't exist!" unless primitive_exists? primitive_name
    primitive_name
  end

  def status(node = nil)
    message = "Call: 'status' for Pacemaker service '#{name}'"
    message += " on node '#{node}'" if node
    Puppet.debug message
    wait_for_online
    disable_basic_service
    cib_reset
    cleanup_with_wait name if primitive_has_failures? name
    out = get_primitive_puppet_status name, node
    Puppet.debug "Return: '#{out}' (#{out.class})"
    out
  end

  def start
    Puppet.debug "Call 'start' for Pacemaker service '#{name}' on node '#{hostname}'"
    enable unless enabled? == :true
    cleanup_with_wait full_name if primitive_has_failures? name
    unban_primitive name
    start_primitive full_name
    constraint_location_add full_name, hostname
    if primitive_is_complex? name
      Puppet.debug "Choose local start for Pacemaker service '#{name}' on node '#{hostname}'"
      wait_for_start name, hostname
    else
      Puppet.debug "Choose global start for Pacemaker service '#{name}' on node '#{hostname}'"
      wait_for_start name
    end
  end

  def stop
    Puppet.debug "Call 'stop' for Pacemaker service '#{name}' on node '#{hostname}'"
    enable unless enabled? == :true
    cleanup_with_wait full_name if primitive_has_failures? name
    if primitive_is_complex? name
      Puppet.debug "Choose local stop for Pacemaker service '#{name}' on node '#{hostname}'"
      ban_primitive name
      wait_for_stop name, hostname
    else
      Puppet.debug "Choose global stop for Pacemaker service '#{name}' on node '#{hostname}'"
      stop_primitive full_name
      wait_for_stop name
    end
  end

  def restart
    Puppet.debug "Call 'restart' for Pacemaker service '#{name}' on node '#{hostname}'"
    unless status(hostname) == 'running'
      Puppet.debug "Pacemaker service '#{name}' is not running on node '#{hostname}'. Skipping restart!"
    end
    stop
    start
  end

  def enable
    Puppet.debug "Call 'enable' for Pacemaker service '#{name}' on node '#{hostname}'"
    manage_primitive name
  end

  def disable
    Puppet.debug "Call 'disable' for Pacemaker service '#{name}' on node '#{hostname}'"
    unmanage_primitive name
  end
  alias :manual_start :disable

  def enabled?
    Puppet.debug "Call 'enabled?' for Pacemaker service '#{name}' on node '#{hostname}'"
    out = get_primitive_puppet_enable name
    Puppet.debug "Return: '#{out}' (#{out.class})"
    out
  end

  # create an extra provider instance to deal with the basic service
  # TODO: what if there is a need to choose non standard provider?
  def extra_provider(service_name = nil, provider_name = nil)
    return @extra_provider if @extra_provider
    begin
      service_name = name unless service_name
      # TODO: we dont't need this 'p_' if there is no second service to stop
      service_name = service_name.gsub /^p_/, '' if service_name.start_with? 'p_'
      param_hash = {}
      param_hash.store :name, service_name
      param_hash.store :provider, provider_name if provider_name
      type = Puppet::Type::Service.new(param_hash)
      @extra_provider = type.provider
    rescue => e
      Puppet.debug "Could not get extra provider for Pacemaker primitive '#{name}': #{e.message}"
      @extra_provider = nil
    end
  end

  # disable and stop the basic service
  # TODO: what if ocf and init use the same pid/run?
  def disable_basic_service
    return unless extra_provider
    begin
      if extra_provider.enableable? and extra_provider.enabled? == :true
        Puppet.debug "Disable basic service '#{extra_provider.name}' using provider '#{extra_provider.class.name}'"
        extra_provider.disable
      else
        Puppet.debug "Basic service '#{extra_provider.name}' is disabled as reported by '#{extra_provider.class.name}' provider"
      end
      if extra_provider.status == :running
        Puppet.debug "Stop basic service '#{extra_provider.name}' using provider '#{extra_provider.class.name}'"
        extra_provider.stop
      else
        Puppet.debug "Basic service '#{extra_provider.name}' is stopped as reported by '#{extra_provider.class.name}' provider"
      end
    rescue => e
      Puppet.debug "Could not disable basic service for Pacemaker primitive '#{name}' using '#{extra_provider.class.name}' provider: #{e.message}"
    end
  end

end
