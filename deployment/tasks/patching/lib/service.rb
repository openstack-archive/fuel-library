module Service

  #TODO record which services were stopped

  UPSTART_DIR='/etc/init'
  SYSV_INIT_DIR='/etc/init.d'

  # get service status from shell command
  # @return String
  def services
    `service --status-all 2>&1`
  end

  def upstart_service?(value)
    File.exists? File.join UPSTART_DIR, value + '.conf'
  end

  def sysv_init_service?(value)
    File.exists? File.join SYSV_INIT_DIR, value
  end

  def upstart_service_enabled?(value)
    override_file = File.join UPSTART_DIR, "#{value}.override"
    return true unless File.exists? override_file
    begin
      !File.read(override_file).include? 'manual'
    rescue
      true
    end
  end

  def redhat_service_enabled?(value)
    out,code = run "chkconfig #{value}"
    code == 0
  end

  def upstart_service_running?(value)
    out,code = run "service #{value} status"
    out.include? 'start/running'
  end

  def sysv_init_service_running?(value)
    out,code = run "service #{value} status"
    code == 0
  end

  def sysv_init_service_enabled?(value)
    out,code = run "invoke-rc.d --quiet --query #{value} start"
    [104, 106].include?(code)
  end

  def service_is_enabled?(value)
    if osfamily == 'Debian'
      return upstart_service_enabled? value if upstart_service? value
      return sysv_init_service_enabled? value if sysv_init_service? value
      false
    elsif osfamily == 'RedHat'
      return upstart_service_enabled? value if upstart_service? value
      return redhat_service_enabled? value if sysv_init_service? value
      false
    else
      raise "Unknown osfamily: #{osfamily}"
    end
  end

  def service_is_running?(value)
      return upstart_service_running? value if upstart_service? value
      return sysv_init_service_running? value if sysv_init_service? value
      false
  end

  # same as services_list but resets mnemoization
  # @return [Hash<String => Symbol>]
  def services_list_with_renew
    @services_list = nil
    services_list
  end

  # parse services into servicer list
  # @return [Hash<String => Symbol>]
  def services_list
    return @services_list if @services_list
    @services_list = {}
    services.split("\n").each do |service|
      fields = service.chomp.split
      case
        when fields[4] == 'running...'
          name = fields[0]
          # status = :running
        when fields[2] == 'stopped'
          name = fields[0]
          # status = :stopped
        when fields[1] == '+'
          name = fields[3]
          # status = :running
        when fields[1] == '-'
          name = fields[3]
          # status = :stopped
        when fields[1] == '?'
          name = fields[3]
          # status = :unknown
        else
          name = nil
          # status = nil
      end

      next unless name

      # replace wrong service name
      name = 'httpd' if name == 'httpd.event' and osfamily == 'RedHat'
      name = 'openstack-keystone' if name == 'keystone' and osfamily == 'RedHat'

      running = service_is_running? name
      enabled = service_is_enabled? name

      @services_list.store name, { :running => running, :enabled => enabled }
    end
    @services_list
  end

  # find services matching regular expression
  # @param regexp <Regexp>
  # @return [Hash<String => Symbol>]
  def services_by_regexp(regexp)
    matched = {}
    services_list.each do |name, status|
      matched.store name, status if name =~ regexp
    end
    matched
  end

  # stop services that match regex
  # @param regexp <Regexp>
  def stop_services_by_regexp(regexp, check_stopped = true, only_enabled = true)
    services_by_regexp(regexp).each do |name, status|
      next unless status[:running] if check_stopped
      next unless status[:enabled] if only_enabled
      log "Try to stop service: #{name}"
      run "service #{name} stop"
    end
  end

  # start services that match regex
  # @param regexp <Regexp>
  def start_services_by_regexp(regexp, check_running = true)
    services_by_regexp(regexp).each do |name, status|
      next if status[:running] if check_running
      log "Try to start service: #{name}"
      run "service #{name} start"
    end
  end

end
