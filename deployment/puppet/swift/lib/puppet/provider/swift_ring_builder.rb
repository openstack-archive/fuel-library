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
            object_hash["#{$3}:#{$4}/#{$5}"] = {
              :id          => $1,
              :zone        => $2,
              :weight      => $6,
              :partitions  => $7,
              :balance     => $8,
              :meta        => $9
            }
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
    ring[resource[:name]]
  end

  def create
    [:zone, :weight].each do |param|
      raise(Puppet::Error, "#{param} is required") unless resource[param]
    end
    swift_ring_builder(
      builder_file_path,
      'add',
      "z#{resource[:zone]}-#{resource[:name]}",
      resource[:weight]
    )
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

  def weight
    ring[resource[:name]][:weight]
    # get the weight
  end

  def weight=(weight)
    swift_ring_builder(
      builder_file_path,
      'set_weight',
      "d#{ring[resource[:name]][:id]}",
      resource[:weight]
    )
    # requires a rebalance
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

