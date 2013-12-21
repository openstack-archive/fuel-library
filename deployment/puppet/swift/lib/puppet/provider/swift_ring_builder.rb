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
          #FIXME: Workaround for Red Hat still running Grizzly
          if Facter.value(:operatingsystem) == 'RedHat'
            if row =~ /^\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\d+\.\d+)\s+(\d+)?\s+\d?(-?\d+\.\d+)\s+(\S*)$/
              object_hash["#{$4}:#{$5}"] = {
                :id          => $1,
                :region      => $2,
                :zone        => $3,
                :partitions  => $8,
                :balance     => $9,
                :meta        => $10,
              }
            else
              Puppet.warning("Unexpected line: #{row}")
            end
          else
            if row =~ /^\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\d+\.\d+)\s+(\d+)?\s+\d?(-?\d+\.\d+)\s*(\S*)$/
              object_hash["#{$4}:#{$5}"] = {
                :id          => $1,
                :region      => $2,
                :zone        => $3,
                :partitions  => $10,
                :balance     => $11,
                :meta        => $12,
              }
            else
              Puppet.warning("Unexpected line: #{row}")
            end
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
    notice("node name: #{resource[:name]}")
    notice("available devs: #{available_devs.keys.sort.inspect}")
    available_devs.keys.each do |dev|
      raise(Puppet::Error, "Device name #{resource[:name]} should not contain underscore") if dev.include?('_')
    end
    raise(Puppet::Error, "Device not found check device on  #{resource[:name]} ") if available_devs.empty?
    return  available_devs.keys.sort == used_devs
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
    @available_devices = {}

    mountpoints = "#{resource[:mountpoints]}".split("\n")
    for i in mountpoints
      @available_devices[i.split[0]] = i.split[1]
    end

    @available_devices
  end

  def used_devs
    if devs = swift_ring_builder(builder_file_path).split("\n")[4..-1]
      @used_devices = devs.collect do |line|
        #Workaround for Red Hat still running Grizzly
        if Facter.value(:operatingsystem) == 'RedHat'
          line.strip.split(/\s+/)[5] if line.match(/#{resource[:name].split(':')[0]}/)
        else
          line.strip.split(/\s+/)[7] if line.match(/#{resource[:name].split(':')[0]}/)
        end
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

