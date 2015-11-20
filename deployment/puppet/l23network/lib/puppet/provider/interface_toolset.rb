require 'puppetx/l23_utils'
require 'yaml'

class Puppet::Provider::InterfaceToolset < Puppet::Provider

  def self.iproute(*cmd)
    actual_cmd = ['ip'] + Array(*cmd)
    rv = []
    IO.popen(actual_cmd.join(' ') + ' 2>&1') do |ff|
      rv = ff.readlines().map{|l| l.chomp()}
      ff.close
      if 0 != $?.exitstatus
        raise Puppet::ExecutionFailure, "Command '#{actual_cmd.join(' ')}' has been failed with exit_code=#{$?.exitstatus}:\n#{rv.join("\n")}"
      end
    end
    return rv
  end

  def self.ovs_vsctl(*cmd)
    actual_cmd = ['ovs-vsctl'] + Array(*cmd)
    rv = []
    IO.popen(actual_cmd.join(' ') + ' 2>&1') do |ff|
      rv = ff.readlines().map{|l| l.chomp()}
      ff.close
      if 0 != $?.exitstatus
        rv = nil
      end
    end
    return rv
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
    debug("Setting #{iface} up")
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
    debug("Setting #{iface} down")
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

  def self.get_routes
    # return array of hashes -- all defined routes.
    rv = []
    # cat /proc/net/route returns information about routing table in format:
    # Iface Destination Gateway   Flags RefCnt Use Metric Mask    MTU Window IRTT
    # eth0  00000000    0101010A  0003   0      0    0    00000000 0    0     0
    # eth0  0001010A    00000000  0001   0      0    0    00FFFFFF 0    0     0
    File.open('/proc/net/route').readlines.reject{|l| l.match(/^[Ii]face.+/) or l.match(/^(\r\n|\n|\s*)$|^$/)}.map{|l| l.split(/\s+/)}.each do |line|
      #https://github.com/kwilczynski/facter-facts/blob/master/default_gateway.rb
      iface = line[0]
      metric = line[6]
      # whether gateway is default
      if line[1] == '00000000'
        dest = 'default'
        dest_addr = nil
        mask = nil
        route_type = 'default'
      else
        dest_addr = [line[1]].pack('H*').unpack('C4').reverse.join('.')
        mask = [line[7]].pack('H*').unpack('B*')[0].count('1')
        dest = "#{dest_addr}/#{mask}"
      end
      # whether route is local
      if line[2] == '00000000'
        gateway = nil
        route_type = 'local'
      else
        gateway = [line[2]].pack('H*').unpack('C4').reverse.join('.')
        route_type = nil
      end
      rv << {
        :destination    => dest,
        :gateway        => gateway,
        :metric         => metric.to_i,
        :type           => route_type,
        :interface      => iface,
      }
    end
    # this sort need for prioritize routes by metrics
    return rv.sort_by{|r| r[:metric]||0}
  end

end

# vim: set ts=2 sw=2 et :
