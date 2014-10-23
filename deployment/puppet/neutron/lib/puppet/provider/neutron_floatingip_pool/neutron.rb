# Load the Neutron provider library to help
require File.join(File.dirname(__FILE__), '..','..','..', 'puppet/provider/neutron')

Puppet::Type.type(:neutron_floatingip_pool).provide(
  :neutron,
  :parent => Puppet::Provider::Neutron
) do

  desc "Manage floating-IP pool for given tenant"

  commands :neutron  => 'neutron'
  commands :keystone => 'keystone'

  # I need to setup caching and what-not to make this lookup performance not suck
  def self.instances
    @floating_ip_cache ||= {}
    # get floating IP list
    f_ip_list = self.floatingip_list('--format=csv', '--field=id', '--field=floating_ip_address')
    return [] if f_ip_list.chomp.empty?

    pools_by_tenant_id = {}
    f_ip_list.split("\n").each do |fip|
      fields=fip.split(',').map{|x| x[1..-2]}
      next if (fields[0] == 'id') or (fields[0].nil?) or (fields.size != 2)
      details = Hash[
        self.floatingip_show('--format', 'shell', fields[0]).split("\n").map{|x| x.split('=')}.select{|x| !x[0].nil?}.map{|x| [x[0].to_sym,x[1][1..-2]]}
      ]
      pools_by_tenant_id[details[:tenant_id]]  ?  pools_by_tenant_id[details[:tenant_id]] += 1  :  pools_by_tenant_id[details[:tenant_id]] = 1
      @floating_ip_cache[details[:id]] = {
        :tenant_id => details[:tenant_id],
        :tenant    => tenant_name_by_id[details[:tenant_id]],
        :ip        => details[:floating_ip_address]
      }
    end
    rv = []
    pools_by_tenant_id.each do |tenn_id, ip_count|
      Puppet::debug("tenant-id='#{tenn_id}'  tenant='#{tenant_name_by_id[tenn_id]}' size=#{ip_count}")
      rv << new(
        :name      => tenant_name_by_id[tenn_id],
        :pool_size => ip_count,
        :ensure    => :present
      )
    end
    rv
  end

  def pool_size
    @property_hash[:pool_size]
  end
  def pool_size=(value)
    delta = @property_hash[:pool_size].to_i - value
    if delta == 0
      nil
    elsif delta > 0
      Puppet::debug("*** will be destroyed #{delta} floating IPs for tenant '#{@property_hash[:name]}'")
      _destroy_N(delta)
    else
      Puppet::debug("*** will be created #{-delta} floating IPs for tenant '#{@property_hash[:name]}'")
      _create_N(-delta)
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    _create_N(@resource[:pool_size])
  end

  def _create_N(n)
      for i in 0...n.to_i do
        auth_neutron('floatingip-create', '--tenant-id', tenant_id[@resource[:name]], @resource[:ext_net])
      end
  end

  def destroy
    _destroy_N((2**((8*0.size)-2))-1) # ruby maxint emulation
  end

  def _destroy_N(n)
    nn = n.to_i
    t_id = tenant_id[@resource[:name]]
    # get floating IP list
    f_ip_list = floatingip_list('--format=csv', '--field=id', '--field=floating_ip_address')
    return if f_ip_list.chomp.empty?
    f_ip_list.split("\n").each do |fip|
      fields=fip.split(',').map{|x| x[1..-2]}
      next if (fields[0].nil?) or (fields.size != 2) or (fields[0] == 'id')
      fip_id = fields[0]
      details = floatingip_cache[fip_id.to_s]
      if details.nil?
        Puppet::debug("*** Can't find in cache floating IP with ID:'#{fip_id}'")
      end
      if details[:tenant_id] == t_id
        auth_neutron('floatingip-delete', fip_id)
        nn -= 1
        break if nn <= 0
      end
    end
  end

  private

    def self.floatingip_cache
      @floating_ip_cache
    end
    def floatingip_cache
      self.class.floatingip_cache
    end

    def self.tenant_id
      @tenant_id ||= list_keystone_tenants
    end
    def tenant_id
      self.class.tenant_id
    end

    def self.tenant_name_by_id
      @tenant_name_by_id ||= list_keystone_tenants.invert()
    end
    def tenant_name_by_id
      self.class.tenant_name_by_id
    end

    def floatingip_list(*args)
      self.class.floatingip_list(args)
    end
    def self.floatingip_list(*args)
      rv = auth_neutron('floatingip-list', args)
      if rv.nil?
        raise(Puppet::ExecutionFailure, "Can't fetch floatingip-list. Neutron or Keystone API not availaible.")
      end
      return rv
    end

    def floatingip_show(*args)
      self.class.floatingip_show(args)
    end
    def self.floatingip_show(*args)
      rv = auth_neutron('floatingip-show', args)
      if rv.nil?
        raise(Puppet::ExecutionFailure, "Can't execute floatingip_show. Neutron or Keystone API not availaible.")
      end
      return rv
    end

end
# vim: set ts=2 sw=2 et :