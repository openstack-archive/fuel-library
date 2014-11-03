$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/provider/keystone'
Puppet::Type.type(:keystone_tenant).provide(
  :keystone,
  :parent => Puppet::Provider::Keystone
) do

  desc <<-EOT
    Provider that uses the keystone client tool to
    manage keystone tenants

    This provider makes a few assumptions/
      1. assumes that the admin endpoint can be accessed via localhost.
      2. Assumes that the admin token and port can be accessed from
         /etc/keystone/keystone.conf

    One string difference, is that it does not know how to change the
    name of a tenant
  EOT

  optional_commands :keystone => "keystone"

  def self.prefetch(resource)
    # rebuild the cahce for every puppet run
    @tenant_hash = nil
  end

  def self.tenant_hash
    @tenant_hash ||= build_tenant_hash
  end

  def tenant_hash
    self.class.tenant_hash
  end

  def instance
    tenant_hash[resource[:name]]
  end

  def self.instances
    tenant_hash.collect do |k, v|
      new(
          :name => k,
          :id   => v[:id]
          )
    end
  end

  def create
    optional_opts = []
    if resource[:description]
      optional_opts.push('--description').push(resource[:description])
    end
    results = auth_keystone(
      'tenant-create',
      '--name', resource[:name],
      '--enabled', resource[:enabled],
      optional_opts
    )

    if results =~ /Property\s|\sValue/
      attrs = self.class.parse_keystone_object(results)
      tenant_hash[resource[:name]] = {
        :ensure      => :present,
        :name        => resource[:name],
        :id          => attrs['id'],
        :enabled     => attrs['enabled'],
        :description => attrs['description'],
      }
    else
      fail("did not get expected message on tenant creation, got #{results}")
    end
  end

  def exists?
    instance
  end

  def destroy
    auth_keystone('tenant-delete', instance[:id])
    instance[:ensure] = :absent
  end

  def enabled=(value)
    Puppet.warning("I am not sure if this is supported yet")
    auth_keystone("tenant-update", '--enabled', value, instance[:id])
    instance[:enabled] = value
  end

  def description
    self.class.get_keystone_object('tenant', instance[:id], 'description')
  end

  def description=(value)
    auth_keystone("tenant-update", '--description', value, instance[:id])
    instance[:description] = value
  end

  [
   :id,
   :enabled,
  ].each do |attr|
    define_method(attr.to_s) do
      instance[attr] || :absent
    end
  end

  private

    def self.build_tenant_hash
      hash = {}
      list_keystone_objects('tenant', 3).each do |tenant|
        hash[tenant[1]] = {
          :id          => tenant[0],
          :enabled     => tenant[2],
        }
      end
      hash
    end
end
