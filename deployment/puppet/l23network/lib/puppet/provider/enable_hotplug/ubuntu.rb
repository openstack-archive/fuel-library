Puppet::Type.type(:enable_hotplug).provide(:ubuntu) do
  defaultfor :osfamily => :debian
  commands   :udevadm  => 'udevadm'

  def self.prefetch(resources)
    instances.each do |provider|
      name = provider.name.to_s
      next unless resources.key? name
      resources[name].provider = provider
    end
  end

  def self.instances
   file_exist = File.exist?('/etc/udev/rules.d/99-disable-network-interface-hotplug.rules')
   result = []
   if file_exist
     result << new({ :name => 'global' , :ensure => :absent })
   else
     result << new({ :name => 'global' , :ensure => :present })
   end
   return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    self.class.instances.each do |provider|
      if provider.name == 'global'
         FileUtils.rm('/etc/udev/rules.d/99-disable-network-interface-hotplug.rules')
         udevadm('control', '--start-exec-queue') 
      end
    end
  end

  def destroy
    info("\n Does not support 'ensure=absent' \n It could be 'ensure=present' ONLY!!! ")
  end

  def flush
    debug 'Call: flush'
  end

end

# vim: set ts=2 sw=2 et :
