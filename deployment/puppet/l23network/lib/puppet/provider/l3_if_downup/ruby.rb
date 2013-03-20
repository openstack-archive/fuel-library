require 'ipaddr'

begin
  require 'util/netstat.rb'
rescue LoadError => e
  # puppet apply does not add module lib directories to the $LOAD_PATH (See
  # #4248). It should (in the future) but for the time being we need to be
  # defensive which is what this rescue block is doing.
  rb_file = File.join(File.dirname(__FILE__), 'util', 'netstat.rb')
  load rb_file if File.exists?(rb_file) or raise e
end

def get_gateway()
  Facter::Util::NetStat.get_route_value('default', 'gw') || Facter::Util::NetStat.get_route_value('0.0.0.0', 'gw')
end

def find_gateway(interface, if_file)
  rv = nil
  def_route = get_gateway()
  if def_route and if_file
    ifile = /\[(\S+)\]/.match(if_file.to_s())
    if ifile
      #notice("RT-def-route: '#{def_route}' int_file: '#{ifile}'")   ################
      ifile = ifile[1]
      begin
        File.open(ifile, 'r').each() do |line|
          gate = /gateway\s+(\d+\.\d+\.\d+\.\d+)/.match(line.to_s()) || /GATEWAY\s*=\s*(\d+\.\d+\.\d+\.\d+)/.match(line.to_s())
          if gate
            gate = gate[1]
            #notice("IN-FILE-GATE: '#{gate}'")
            if gate == def_route
              rv = gate
              #notice("IN-FILE-GATE: '#{gate}'  rv = gate")
            end
          end
        end
      rescue
        notice("Can't open file '#{ifile}'")
      end
    end
  else
    notice("Default route: UNKNOWN")
  end
  return rv
end

Puppet::Type.type(:l3_if_downup).provide(:ruby) do
  confine :osfamily => [:debian, :redhat]
  optional_commands(
    :ifup => 'ifup',
    :ifdn => 'ifdown',
    :ip   => "ip",
    :kill => "kill",
    :ps   => "ps",
    :ping => "ping"
  )

  def ping_ip(ipaddr,timeout)
    end_time = Time.now.to_i + timeout
    rv = false
    loop do
      begin
        ping(['-c1',ipaddr])
        rv = true
        break
      rescue Puppet::ExecutionFailure => e
        current_time = Time.now.to_i
        if current_time > end_time
          break
        else
          wa = end_time - current_time
          notice("Host #{ipaddr} not answered. Wait up to #{wa} sec.")
          #notice e.message
        end
        sleep(0.5) # do not remove!!! It's a positive brake!
      end
    end
    return rv
  end

  def restart()
    begin # downing inteface
      ifdn(@resource[:interface])
      notice("Interface '#{@resource[:interface]}' down.")
      sleep @resource[:sleep_time]
    rescue Puppet::ExecutionFailure
      notice("Can't put interface '#{@resource[:interface]}' to DOWN state.")
    end
    if @resource[:kill_dhclient] and Facter.value(:osfamily) == 'Debian'
      # kill forgotten dhclient in Ubuntu
      dhclient = @resource[:dhclient_name]
      iface = @resource[:interface]
      ps('axf').each_line do |line|
        rg = line.match("^\s*([0-9]+)\s+.*#{dhclient}\s+.*(\s#{iface})")
        if rg
          begin
            kill(['-9',rg[1]])
            notice("Killed forgotten #{dhclient} with PID=#{rg[1]} succeffuly...")
            sleep @resource[:sleep_time]
          rescue Puppet::ExecutionFailure
            notice("Can't kill #{dhclient} with PID=#{rg[1]}")
          end
        end
      end
    end
    if @resource[:flush]  # Flushing IP addresses from interface
      begin
        ip(['addr', 'flush', @resource[:interface]])
        notice("Interface '#{@resource[:interface]}' flush.")
        sleep @resource[:sleep_time]
      rescue Puppet::ExecutionFailure
        notice("Can't flush interface '#{@resource[:interface]}'.")
      end
    end
    return true if @resource[:onlydown]
    begin  # Put interface to UP state
      ifup(@resource[:interface])
      notice("Interface '#{@resource[:interface]}' up.")
      if @resource[:check_by_ping] == 'gateway'
        # find gateway for interface and ping it
        ip_to_ping = find_gateway(@resource[:interface], @resource[:subscribe])
        if ip_to_ping
          notice("Interface '#{@resource[:interface]}' Gateway #{ip_to_ping} will be pinged. Wait up to #{@resource[:check_by_ping_timeout]} sec.")
          rv = self.ping_ip(ip_to_ping, @resource[:check_by_ping_timeout].to_i)
          if rv
            notice("Interface '#{@resource[:interface]}' #{ip_to_ping} is OK")
          else
            notice("Interface '#{@resource[:interface]}' #{ip_to_ping} no answer :(")
          end
        end
      elsif @resource[:check_by_ping] == 'none'
        #pass
        notice("Interface '#{@resource[:interface]}' Don't checked.")
      else
        # IP address given
        notice("Interface '#{@resource[:interface]}' IP #{@resource[:check_by_ping]} will be pinged. Wait up to #{@resource[:check_by_ping_timeout]} sec.")
        rv = self.ping_ip(@resource[:check_by_ping], @resource[:check_by_ping_timeout].to_i)
        if rv
          notice("Interface '#{@resource[:interface]}' #{@resource[:check_by_ping]} is OK")
        else
          notice("Interface '#{@resource[:interface]}' #{@resource[:check_by_ping]} no answer :(")
        end
      end
      notice("Interface '#{@resource[:interface]}' done.")
    rescue Puppet::ExecutionFailure
      notice("Can't put interface '#{@resource[:interface]}' to UP state.")
    end
  end

  def create()
    if ! @resource[:refreshonly]
      restart()
    end
  end

  def destroy()
  end

  # def self.instances
  #   if_list = []
  #   File.open("/proc/net/dev", "r") do |raw_iflist|
  #     while (line = raw_iflist.gets)
  #       rg = line.match('^\s*([0-9A-Za-z\.\-\_]+):')
  #       if rg
  #         if_list.push(rg[1].to_sym)
  #       end  
  #     end
  #   end
  #   return if_list
  # end
end
