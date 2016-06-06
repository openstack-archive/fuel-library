require 'hiera'
ENV['LANG'] = 'C'

module Puppet::Parser::Functions
  newfunction(:neutron_network_id_getter, :type => :rvalue) do |argv|
    if argv.size != 1
      raise(Puppet::ParseError, "neutron_network_id_getter(): Requires neutron network name.")
    end

    network_name = argv[0]

    hiera = Hiera.new(:config => '/etc/hiera.yaml')
    neutron_config = hiera.lookup 'neutron_config', {}, {}
    management_vip = hiera.lookup 'management_vip', {}, {}
    auth_addr = hiera.lookup 'service_endpoint', "#{management_vip}", {}
    tenant_name = neutron_config['keystone']['admin_tenant'].nil? ? "services" : neutron_config['keystone']['admin_tenant']
    user_name = neutron_config['keystone']['admin_user'].nil? ? "neutron" : neutron_config['keystone']['admin_user']
    endpoint_type = "internalURL"
    region_name = hiera.lookup 'region', 'RegionOne', {}
    ssl_hash = hiera.lookup 'use_ssl', {}, {}

    if ssl_hash['keystone_internal']
        auth_proto = 'https'
        auth_addr = ssl_hash['keystone_internal_hostname'] || auth_addr
    else
        auth_proto = 'http'
    end

    ENV['OS_TENANT_NAME']="#{tenant_name}"
    ENV['OS_USERNAME']="#{user_name}"
    ENV['OS_PASSWORD']="#{neutron_config['keystone']['admin_password']}"
    ENV['OS_AUTH_URL']="#{auth_proto}://#{auth_addr}:5000/v2.0"
    ENV['OS_ENDPOINT_TYPE'] = "#{endpoint_type}"
    ENV['OS_REGION_NAME']="#{region_name}"

    stdout = `openstack network show #{network_name} -f value -c id`

    return stdout
  end
end
