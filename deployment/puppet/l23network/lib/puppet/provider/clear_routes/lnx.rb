require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:clear_routes).provide(:lnx) do
  defaultfor :osfamily   => :linux
  commands   :ip         => 'ip'


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
    ip('-4', 'route', 'list', '0/0').split(/\n+/).sort.each do |line|
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
    info("\n Does not support 'ensure=present' \n It could be only 'ensure=absent' !!! ")
  end

  def destroy
    cmdline = ['-4', 'route', 'del', '0/0']
      rc = 0
      while rc == 0
        # we should remove route repeatedly to prevent from situation
        # when there are multiple default gateways but with different metrics
        begin
          ip(cmdline)
        rescue
          rc = 1
        end
      end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
    @old_property_hash = {}
    @old_property_hash.merge! @property_hash
  end

end
# vim: set ts=2 sw=2 et :
