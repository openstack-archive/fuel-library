Puppet::Type.type(:enable_hotplug).provide(:lnx) do
  defaultfor :kernel => :linux
  commands   :udevadm  => 'udevadm'

  def self.prefetch(resources)
    instances.each do |provider|
      name = provider.name.to_s
      next unless resources.key? name
      resources[name].provider = provider
    end
  end

  def self.instances
   file_exist = File.exist?('/run/disable-network-interface-hotplug') or File.exist?('/var/run/disable-network-interface-hotplug')
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
         if File.exist?('/run/disable-network-interface-hotplug')
           FileUtils.rm('/run/disable-network-interface-hotplug')
         else
           FileUtils.rm('/var/run/disable-network-interface-hotplug')
         end
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
