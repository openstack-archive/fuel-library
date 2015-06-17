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

    Doesn't do any changes.
  EOT

  optional_commands :keystone => "keystone"

  def self.prefetch(resource)
    # rebuild the cahce for every puppet run
    @tenant_hash = nil
  end

  def self.tenant_hash
    @tenant_hash = build_tenant_hash
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
    warn "This provider is read-only!"
  end

  def exists?
    instance
  end

  def destroy
    warn "This provider is read-only!"
  end

  def enabled=(value)
    warn "This provider is read-only!"
  end

  def description
    self.class.get_keystone_object('tenant', instance[:id], 'description')
  end

  def description=(value)
    warn "This provider is read-only!"
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
