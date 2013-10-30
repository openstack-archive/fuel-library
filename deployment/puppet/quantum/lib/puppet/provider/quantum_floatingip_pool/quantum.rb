# Load the Quantum provider library to help
require File.join(File.dirname(__FILE__), '..','..','..', 'puppet/provider/quantum')

Puppet::Type.type(:quantum_floatingip_pool).provide(
  :quantum,
  :parent => Puppet::Provider::Quantum
) do

  desc "Manage floating-IP pool for given tenant"

  commands :quantum  => 'quantum'
  commands :keystone => 'keystone'
  commands :sleep => 'sleep'

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

  def self.prefetch(resources)
    instances.each do |i|
      res = resources[i.name.to_s]
      if ! res.nil?
        res.provider = i
      end
    end
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
        retries = 30
        loop do
          begin
            auth_quantum('floatingip-create', '--tenant-id', tenant_id[@resource[:name]], @resource[:ext_net])
            break
          rescue Exception => e
            notice("Can't connect to quantum backend. Waiting for retry...")
            retries -= 1
            if retries <= 1
              notice("Can't connect to quantum backend. No more retries.")
              raise(e)
            end
            sleep 2
          end
        end
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
        retries = 30
        loop do
          begin
            auth_quantum('floatingip-delete', fip_id)
            break
          rescue Exception => e
            notice("Can't connect to quantum backend. Waiting for retry...")
            retries -= 1
            if retries <= 1
              notice("Can't connect to quantum backend. No more retries.")
              raise(e)
            end
            sleep 2
          end
        end
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
      rv = ''
      retries = 30
      loop do
        begin
          rv = auth_quantum('floatingip-list', args)
          break
        rescue Exception => e
          notice("Can't connect to quantum backend. Waiting for retry...")
          retries -= 1
          if retries <= 1
            notice("Can't connect to quantum backend. No more retries.")
            raise(e)
          end
          sleep 2
        end
      end
      return rv
    end


    def floatingip_show(*args)
      self.class.floatingip_show(args)
    end
    def self.floatingip_show(*args)
      rv = ''
      retries = 30
      loop do
        begin
          rv = auth_quantum('floatingip-show', args)
          break
        rescue Exception => e
          notice("Can't connect to quantum backend. Waiting for retry...")
          retries -= 1
          if retries <= 1
            notice("Can't connect to quantum backend. No more retries.")
            raise(e)
          end
          sleep 2
        end
      end
      return rv
    end

end
# vim: set ts=2 sw=2 et :