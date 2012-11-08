$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/provider/keystone'
Puppet::Type.type(:keystone_role).provide(
  :keystone,
  :parent => Puppet::Provider::Keystone
) do

  desc <<-EOT
    Provider that uses the keystone client tool to
    manage keystone roles
  EOT

  optional_commands :keystone => "keystone"

  def self.prefetch(resource)
    # rebuild the cahce for every puppet run
    @role_hash = nil
  end

  def self.role_hash
    @role_hash ||= build_role_hash
  end

  def role_hash
    self.class.role_hash
  end

  def self.instances
    role_hash.collect do |k, v|
      new(:name => k)
    end
  end

  def create
    auth_keystone(
      'role-create',
      '--name', resource[:name]
    )
  end

  def exists?
    role_hash[resource[:name]]
  end

  def destroy
    auth_keystone('role-delete', role_hash[resource[:name]][:id])
  end

  def id
    role_hash[resource[:name]][:id]
  end

  private

    def self.build_role_hash
      hash = {}
      list_keystone_objects('role', 2).each do |role|
        hash[role[1]] = {
          :id          => role[0],
        }
      end
      hash
    end

end
