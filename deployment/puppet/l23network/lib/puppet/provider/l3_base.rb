require 'puppetx/l23_utils'
require 'yaml'

class Puppet::Provider::L3_base < Puppet::Provider

  def self.iproute(*cmd)
    actual_cmd = ['ip'] + Array(*cmd)
    ff = IO.popen(actual_cmd.join(' '))
    rv = ff.readlines().map{|l| l.chomp()}
    # exception should be exception here
    return rv
  end

  def self.prefetch(resources)
    interfaces = instances
    resources.keys.each do |name|
      if provider = interfaces.find{ |ii| ii.name == name }
        resources[name].provider = provider
      end
    end
  end

  # ---------------------------------------------------------------------------

  def self.iface_exist?(iface)
    File.exist? "/sys/class/net/#{iface}"
  end

  def self.set_mtu(iface, mtu=1500)
    if File.symlink?("/sys/class/net/#{iface}")
      debug("Set MTU to '#{mtu}' for interface '#{iface}'")
      set_sys_class("/sys/class/net/#{iface}/mtu", mtu)
    end
  end

  # ---------------------------------------------------------------------------

  def self.set_sys_class(property, value)
    debug("SET sys.property: #{property} << #{value}")
    begin
      property_file = File.open(property, 'a')
      property_file.write("#{value.to_s}")
      property_file.close
      rv = true
    rescue Exception => e
      debug("Non-fatal-Error: Can't set property '#{property}' to '#{value}': #{e.message}")
      rv = false
    end
    return rv
  end

  def self.get_sys_class(property, array=false)
    as_array = (array  ?  ' as array'  :  '')
    debug("GET sys.property: #{property}#{as_array}.")
    begin
      rv = File.open(property).read.split(/\s+/)
    rescue Exception => e
      debug("Non-fatal-Error: Can't get property '#{property}': #{e.message}")
      rv = ['']
    end
    (array  ?  rv  :  rv[0])
  end

  # ---------------------------------------------------------------------------
  def self.get_iface_state(iface)
    # returns:
    #    true  -- interface in UP state
    #    false -- interface in UP state, but no-carrier
    #    nil   -- interface in DOWN state
    begin
      1 == File.open("/sys/class/net/#{iface}/carrier").read.chomp.to_i
    rescue
      # if interface is down, this file can't be read
      nil
    end
  end

  def self.interface_up(iface, force=false)
    cmd = ['link', 'set', 'up', 'dev', iface]
    cmd.insert(0, '--force') if force
    begin
      iproute(cmd)
      rv = true
    rescue Exception => e
      debug("Non-fatal-Error: Can't put interface '#{iface}' to UP state: #{e.message}")
      rv = false
    end
    return rv
  end

  def self.interface_down(iface, force=false)
    cmd = ['link', 'set', 'down', 'dev', iface]
    cmd.insert(0, '--force') if force
    begin
      iproute(cmd)
      rv = true
    rescue Exception => e
      debug("Non-fatal-Error: Can't put interface '#{iface}' to DOWN state: #{e.message}")
      rv = false
    end
    return rv
  end
  # ---------------------------------------------------------------------------
  def self.ipaddr_exist?(if_name)
    rv = false
    iproute(['-o', 'addr', 'show', 'dev', if_name]).map{|l| l.split(/\s+/)}.each do |line|
      if line[2].match(/^inet\d?$/)
        rv=true
        break
      end
    end
    return rv
  end

  def self.addr_flush(iface, force=false)
    cmd = ['addr', 'flush', 'dev', iface]
    cmd.insert(0, '--force') if force
    begin
      iproute(cmd)
      rv = true
    rescue Exception => e
      debug("Non-fatal-Error: Can't flush addr for interface '#{iface}': #{e.message}")
      rv = false
    end
    return rv
  end

  def self.route_flush(iface, force=false)
    cmd = ['route', 'flush', 'dev', iface]
    cmd.insert(0, '--force') if force
    begin
      iproute(cmd)
      rv = true
    rescue Exception => e
      debug("Non-fatal-Error: Can't flush routes for interface '#{iface}': #{e.message}")
      rv = false
    end
    return rv
  end

  # ---------------------------------------------------------------------------


  def self.get_if_addr_mappings
    if_list = {}
    ip_a = iproute(['-f', 'inet', 'addr', 'show'])
    if_name = nil
    ip_a.each do |line|
      line.rstrip!
      case line
      when /^\s*\d+\:\s+([\w\-\.]+)[\:\@]/i
        if_name = $1
        if_list[if_name] = { :ipaddr => [] }
      when /^\s+inet\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2})/
        next if if_name.nil?
        if_list[if_name][:ipaddr] << $1
      else
        next
      end
    end
    return if_list
  end

  def self.get_if_defroutes_mappings
    rou_list = {}
    ip_a = iproute(['-f', 'inet', 'route', 'show'])
    ip_a.each do |line|
      line.rstrip!
      next if !line.match(/^\s*default\s+via\s+([\d\.]+)\s+dev\s+([\w\-\.]+)(\s+metric\s+(\d+))?/)
      metric = $4.nil?  ?  :absent  :  $4.to_i
      rou_list[$2] = { :gateway => $1, :gateway_metric => metric } if rou_list[$2].nil?  # do not replace to gateway with highest metric
    end
    return rou_list
  end

end

# vim: set ts=2 sw=2 et :