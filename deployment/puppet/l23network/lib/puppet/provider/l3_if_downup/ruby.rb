Puppet::Type.type(:l3_if_downup).provide(:ruby) do
  confine :osfamily => [:debian, :redhat]
  optional_commands :ifup => 'ifup',
                    :ifdn => 'ifdown',
                    :ip   => "ip",
                    :kill => "kill",
                    :ps   => "ps"

  def restart
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
    begin  # Put interface to UP state
      ifup(@resource[:interface])
      notice("Interface '#{@resource[:interface]}' up.")
      sleep @resource[:sleep_time]
    rescue Puppet::ExecutionFailure
      notice("Can't put interface '#{@resource[:interface]}' to UP state.")
    end
  end

  def create
    if ! @resource[:refreshonly]
      restart()
    end
  end

  def destroy
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
