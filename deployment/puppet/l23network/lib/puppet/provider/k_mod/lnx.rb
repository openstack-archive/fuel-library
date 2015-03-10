require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:k_mod).provide(:lnx) do
  defaultfor :osfamily   => :linux
  commands   :mod_load   => 'modprobe',
             :ls_mod     => 'lsmod',
             :mod_unload => 'rmmod'


  def self.prefetch(resources)
    interfaces = instances
    resources.keys.each do |name|
      if provider = interfaces.find{ |ii| ii.name == name }
        resources[name].provider = provider
      end
    end
  end

  def self.instances
    rv = []
    ls_mod.split(/\n+/).sort.each do |line|
      name = line.split(/\s+/)[0]
      rv << new({
        :ensure       => :present,
        :name         => name,
      })
    end
    rv
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    mod_load(@resource[:module])
  end

  def destroy
    mod_unload(@resource[:module])
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
    @old_property_hash = {}
    @old_property_hash.merge! @property_hash
  end

  # def flush
  #   if ! @property_flush.empty?
  #     debug("FLUSH properties: #{@property_flush}")
  #     #
  #     # FLUSH changed properties
  #     # if ! @property_flush[:mtu].nil?
  #     #   File.open("/sys/class/net/#{@resource[:interface]}/mtu", "w") { |f| f.write(@property_flush[:mtu]) }
  #     # end
  #     @property_hash = resource.to_hash
  #   end
  # end

end
# vim: set ts=2 sw=2 et :