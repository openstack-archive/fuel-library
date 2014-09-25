require File.join(File.dirname(__FILE__), '..','..','..',
                  'puppet/provider/neutron')

Puppet::Type.type(:neutron_router).provide(
  :neutron,
  :parent => Puppet::Provider::Neutron
) do
  desc <<-EOT
    Neutron provider to manage neutron_router type.

    Assumes that the neutron service is configured on the same host.
  EOT

  commands :neutron => 'neutron'

  mk_resource_methods

  def self.instances
    list_neutron_resources('router').collect do |id|
      attrs = get_neutron_resource_attrs('router', id)
      new(
        :ensure                    => :present,
        :name                      => attrs['name'],
        :id                        => attrs['id'],
        :admin_state_up            => attrs['admin_state_up'],
        :external_gateway_info     => attrs['external_gateway_info'],
        :status                    => attrs['status'],
        :tenant_id                 => attrs['tenant_id']
      )
    end
  end

  def self.prefetch(resources)
    instances_ = instances
    resources.keys.each do |name|
      if provider = instances_.find{ |instance| instance.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    opts = Array.new

    if @resource[:admin_state_up] == 'False'
      opts << '--admin-state-down'
    end

    if @resource[:tenant_name]
      tenant_id = self.class.get_tenant_id(model.catalog,
                                           @resource[:tenant_name])
      opts << "--tenant_id=#{tenant_id}"
    elsif @resource[:tenant_id]
      opts << "--tenant_id=#{@resource[:tenant_id]}"
    end

    results = auth_neutron("router-create", '--format=shell',
                           opts, resource[:name])

    if results =~ /Created a new router:/
      attrs = self.class.parse_creation_output(results)
      @property_hash = {
        :ensure                    => :present,
        :name                      => resource[:name],
        :id                        => attrs['id'],
        :admin_state_up            => attrs['admin_state_up'],
        :external_gateway_info     => attrs['external_gateway_info'],
        :status                    => attrs['status'],
        :tenant_id                 => attrs['tenant_id'],
      }

      if @resource[:gateway_network_name]
        results = auth_neutron('router-gateway-set',
                               @resource[:name],
                               @resource[:gateway_network_name])
        if results =~ /Set gateway for router/
          attrs = self.class.get_neutron_resource_attrs('router',
                                                        @resource[:name])
          @property_hash[:external_gateway_info] = \
            attrs['external_gateway_info']
        else
          fail(<<-EOT
did not get expected message on setting router gateway, got #{results}
EOT
               )
        end
      end
    else
      fail("did not get expected message on router creation, got #{results}")
    end
  end

  def destroy
    auth_neutron('router-delete', name)
    @property_hash[:ensure] = :absent
  end

  def gateway_network_name
    if @gateway_network_name == nil and gateway_network_id
      Puppet::Type.type('neutron_network').instances.each do |instance|
        if instance.provider.id == gateway_network_id
          @gateway_network_name = instance.provider.name
        end
      end
    end
    @gateway_network_name
  end

  def gateway_network_name=(value)
    if value == ''
      auth_neutron('router-gateway-clear', name)
    else
      auth_neutron('router-gateway-set', name, value)
    end
  end

  def parse_gateway_network_id(external_gateway_info_)
    match_data = /\{"network_id": "(.*?)"/.match(external_gateway_info_)
    if match_data
      match_data[1]
    else
      ''
    end
  end

  def gateway_network_id
    @gateway_network_id ||= parse_gateway_network_id(external_gateway_info)
  end

  def admin_state_up=(value)
    auth_neutron('router-update', "--admin-state-up=#{value}", name)
  end

end
