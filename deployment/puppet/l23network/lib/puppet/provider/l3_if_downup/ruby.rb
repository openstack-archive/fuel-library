

Puppet::Type.type(:l3_if_downup).provide(:ruby) do
  confine :osfamily => [:debian, :redhat]
  optional_commands :ifup => 'ifup',
                    :ifdn => 'ifdown',
                    :ip   => "ip"

  def restart
    begin
      ifdn(@resource[:interface])
      notice("Interface '#{@resource[:interface]}' down.")
    rescue Puppet::ExecutionFailure
      # pass
    end
    if @resource[:flush]  
      begin
        ip(['addr', 'flush', @resource[:interface]])
        notice("Interface '#{@resource[:interface]}' flush.")
      rescue Puppet::ExecutionFailure
        # pass
      end
    end
    begin
      ifup(@resource[:interface])
      notice("Interface '#{@resource[:interface]}' up.")
    rescue Puppet::ExecutionFailure
      # pass
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
