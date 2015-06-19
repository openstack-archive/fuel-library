$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/provider/keystone'
Puppet::Type.type(:keystone_service).provide(
  :keystone,
  :parent => Puppet::Provider::Keystone
) do

  desc <<-EOT
    Provider that uses the keystone client tool to
    manage keystone services

    This provider makes a few assumptions/
      1. assumes that the admin endpoint can be accessed via localhost.
      2. Assumes that the admin token and port can be accessed from
         /etc/keystone/keystone.conf

    Does not support the ability to list all

    Doesn't do any changes.
  EOT

  optional_commands :keystone => "keystone"

  def self.prefetch(resource)
    # rebuild the cahce for every puppet run
    @service_hash = nil
  end

  def self.service_hash
    @service_hash = build_service_hash
  end

  def service_hash
    self.class.service_hash
  end

  def self.instances
    service_hash.collect do |k, v|
      new(:name => k)
    end
  end

  def create
    warn "This provider is read-only!"
  end

  def exists?
    service_hash[resource[:name]]
  end

  def destroy
    warn "This provider is read-only!"
  end

  def id
    service_hash[resource[:name]][:id]
  end

  def type
    service_hash[resource[:name]][:type]
  end

  def type=(value)
    warn "This provider is read-only!"
  end

  def description
    service_hash[resource[:name]][:description]
  end

  def description=(value)
    warn "This provider is read-only!"
  end

  private

    def self.build_service_hash
      hash = {}
      list_keystone_objects('service', 4).each do |user|
        hash[user[1]] = {
          :id          => user[0],
          :type        => user[2],
          :description => user[3]
        }
      end
      hash
    end

end
