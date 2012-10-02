class Puppet::Provider::SwiftRingBuilder < Puppet::Provider

  def self.instances
    # TODO iterate through the databases
    # and add the database that we used a property
    ring.keys.collect do |name|
      new(:name => name)
    end
  end


  def self.lookup_ring
    object_hash = {}
    if File.exists?(builder_file_path)
      if rows = swift_ring_builder(builder_file_path).split("\n")[4..-1]
        rows.each do |row|
          if row =~ /^\s+(\d+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\d+\.\d+)\s+(\d+)\s+(-?\d+\.\d+)\s+(\S*)$/
            object_hash["#{$3}:#{$4}"] = {
              :id          => $1,
              :zone        => $2,
              :partitions  => $7,
              :balance     => $8,
              :meta        => $9
            }
            #notice(object_hash.values.inspect)
          else
            Puppet.warning("Unexpected line: #{row}")
          end
        end
      end
    end
    object_hash
  end

  def ring
    self.class.ring
  end

  def builder_file_path
    self.class.builder_file_path
  end

  def exists?
    #notice("vailable_devs.keys.sort.inspect #{available_devs.keys.sort.inspect}")
    #notice("used_devs #{used_devs.inspect}")
    !available_devs.empty? or !used_devs.empty?
    #return  available_devs.keys.sort == used_devs
    #ring[resource[:name]]
  end

  def create
    raise(Puppet::Error, "#{param} is required") unless resource[:zone]

    # remove the missing devices
    destroy

    (available_devs.keys - used_devs).each do |mountpoint|
      notice("*** create device: #{mountpoint}")
      swift_ring_builder(builder_file_path,
        'add',
        "z#{resource[:zone]}-#{resource[:name]}/#{mountpoint}",
        available_devs[mountpoint]
      )
    end
  end

  def destroy
    (used_devs - available_devs.keys).each do |mountpoint|
      notice("*** remove device: #{mountpoint}")
      swift_ring_builder(builder_file_path,
        'remove',
        "#{resource[:name]}/#{mountpoint}"
      )
    end
  end

  def available_devs
    #return @available_devices if @available_devices

    @available_devices = {}
    mountpoints = "#{resource[:mountpoints]}".split("\n")
    for i in mountpoints
      @available_devices[i.split[0]] = i.split[1]
    end

    @available_devices
  end

  def used_devs
   # return @used_devices if @used_devices

    if devs = swift_ring_builder(builder_file_path).split("\n")[4..-1]
      @used_devices = devs.collect do |line|
        line.strip.split(/\s+/)[4] if line.match(/#{resource[:name].split(':')[0]}/)
      end.compact.sort
    else
      []
    end
  end

  def id
    ring[resource[:name]][:id]
  end

  def id=(id)
    raise(Puppet::Error, "Cannot assign id, it is immutable")
  end

  def zone
    ring[resource[:name]][:zone]
  end

  # TODO - is updating the zone supported?
  def zone=(zone)
    Puppet.warning('Setting zone is not yet supported, I am not even sure if it is supported')
  end

  def partitions
    ring[resource[:name]][:partitions]
  end

  def partitions=(part)
    raise(Puppet::Error, "Cannot set partitions, it is set by rebalancing")
  end

  def balance
    ring[resource[:name]][:balance]
  end

  def balance=(balance)
    raise(Puppet::Error, "Cannot set balance, it is set by rebalancing")
  end

  def meta
    ring[resource[:name]][:meta]
  end

  def meta=(meta)
    raise(Puppet::Error, "Cannot set meta, I am not sure if it makes sense or what it is for")
  end

end

