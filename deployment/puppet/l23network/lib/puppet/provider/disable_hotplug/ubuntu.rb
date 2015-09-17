Puppet::Type.type(:disable_hotplug).provide(:ubuntu) do
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
   if get_job_instances().empty? and file_exist
     rvv << new({ :name => 'global' , :ensure => :present })
   else
     rvv << new({ :name => 'global' , :ensure => :absent })
   end
   return rvv
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    self.class.instances.each do |provider|
      if provider.name == 'global'
         interface_names = self.class.get_job_instances()
         bonds = interface_names.select { |x| x =~ %r{bond\d+}  }
         p "BONDS #{bonds.sort}"
         interface_names = bonds.sort | interface_names
         interface_names.each do |instance|
            regex = %r{^network-interface\s+\((.*)\)\s+start/running}
            interface_name = instance.scan(regex).join()
            #p "RRRRRRRRRRRRRRRRRR INT #{interface_name}"
            cmd = ['stop', 'network-interface', "INTERFACE=#{interface_name}" ]
            initctl(cmd)
            ifup_cmd = [ '--allow', 'auto', interface_name ]
            #ifup_cmd += [ '&' ] if interface_name =~ %r{bond\d+}
            ifup(ifup_cmd)
            p "INTERFACE #{interface_name} "
         end
         begin
           file = File.open('/etc/init/network-interface.override', 'w')
           file.write('manual')
         rescue IOError => e
           #exception handling
         ensure
           file.close unless file.nil?
         end
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
