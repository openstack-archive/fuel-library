Puppet::Type.type(:enable_hotplug).provide(:ubuntu) do
  defaultfor :osfamily => :linux
  commands   :initctl  => 'initctl',
             :ifup     => 'ifup'

  def self.prefetch(resources)
    instances.each do |provider|
      name = provider.name.to_s
      next unless resources.key? name
      resources[name].provider = provider
    end
  end

  def self.get_job_instances
    rv = []
    list = initctl('list')
    list.each_line do |line|
      rv<<line if line.match(%r{network-interface \(.*\) start/running})
    end
    return rv
  end

  def self.instances
   file_exist = File.exist?('/etc/init/network-interface.override')
   rvv = []
   if file_exist
     rvv << new({ :name => 'global' , :ensure => :absent })
   else
     rvv << new({ :name => 'global' , :ensure => :present })
   end
   return rvv
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    info("\n Does not support 'ensure=present' \n It could be 'ensure=absent' ONLY!!! ")
    self.class.instances.each do |provider|
      if provider.name == 'global'
         FileUtils.rm('/etc/init/network-interface.override')
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
