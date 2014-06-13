$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/provider/keystone'
Puppet::Type.type(:keystone_endpoint).provide(
  :keystone,
  :parent => Puppet::Provider::Keystone
) do

  desc <<-EOT
    Provider that uses the keystone client tool to
    manage keystone endpoints

    This provider makes a few assumptions/
      1. assumes that the admin endpoint can be accessed via localhost.
      2. Assumes that the admin token and port can be accessed from
         /etc/keystone/keystone.conf
  EOT

  optional_commands :keystone => "keystone"

  def self.prefetch(resource)
    # rebuild the cahce for every puppet run
    @endpoint_hash = nil
  end

  def self.endpoint_hash
    @endpoint_hash ||= build_endpoint_hash
  end

  def endpoint_hash
    self.class.endpoint_hash
  end

  def self.instances
    endpoint_hash.collect do |k, v|
      new(:name => k)
    end
  end

  def create
    optional_opts = []
    {
      :region       => '--region',
      :public_url   => '--publicurl',
      :internal_url => '--internalurl',
      :admin_url    => '--adminurl'
    }.each do |param, opt|
      if resource[param]
        optional_opts.push(opt).push(resource[param])
      end
    end

    if resource[:name].match('/')
      (region, service_name) = resource[:name].split('/')
      resource[:region] = region
      optional_opts.push('--region').push(resource[:region])
    else
      service_name = resource[:name]
    end

    service_id = self.class.list_keystone_objects('service', 4).detect do |user|
      user[1] == service_name
    end.first

    auth_keystone(
      'endpoint-create',
      '--service-id', service_id,
      optional_opts
    )
  end

  def exists?
    endpoint_hash[resource[:name]]
  end

  def destroy
    auth_keystone('endpoint-delete', endpoint_hash[resource[:name]][:id])
  end

  def id
    endpoint_hash[resource[:name]][:id]
  end

  def region
    endpoint_hash[resource[:name]][:region]
  end

  def public_url
    endpoint_hash[resource[:name]][:public_url]
  end

  def internal_url
    endpoint_hash[resource[:name]][:internal_url]
  end

  def admin_url
    endpoint_hash[resource[:name]][:admin_url]
  end

  def public_url=(value)
    destroy
    endpoint_hash[resource[:name]][:public_url] = value
    create
  end

  def internal_url=(value)
    destroy
    endpoint_hash[resource[:name]][:internal_url] = value
    create
  end

  def admin_url=(value)
    destroy
    endpoint_hash[resource[:name]][:admin_url]
    create
  end

  private

    def self.build_endpoint_hash
      hash = {}
      list_keystone_objects('endpoint', [5,6]).each do |endpoint|
        service_id   = get_service_id(endpoint[0])
        service_name = get_keystone_object('service', service_id, 'name')
        hash[service_name] = {
          :id           => endpoint[0],
          :region       => endpoint[1],
          :public_url   => endpoint[2],
          :internal_url => endpoint[3],
          :admin_url    => endpoint[4],
          :service_id   => service_id
        }
      end
      hash
    end

    # TODO - this needs to be replaced with a call to endpoint-get
    # but endpoint-get is not currently supported from the admin url
    def self.get_service_id(endpoint_id)
      `python -c "from keystoneclient.v2_0 import client ; import os ; print [e.service_id for e in client.Client(endpoint='#{admin_endpoint}', token='#{admin_token}').endpoints.list() if e.id == u'#{endpoint_id}'][0]"`.strip()
    end

end
