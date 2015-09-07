#!/usr/bin/env ruby
require 'hiera'

ENV['LANG'] = 'C'

hiera = Hiera.new(:config => '/etc/hiera.yaml')
glanced = hiera.lookup 'glance', {} , {}
management_vip = hiera.lookup 'management_vip', nil, {}
auth_addr = hiera.lookup 'service_endpoint', "#{management_vip}", {}
tenant_name = glanced['tenant'].nil? ? "services" : glanced['tenant']
user_name = glanced['user'].nil? ? "glance" : glanced['user']
endpoint_type = glanced['endpoint_type'].nil? ? "internalURL" : glanced['endpoint_type']
region_name = hiera.lookup 'region', 'RegionOne', {}
ironic_hash = hiera.lookup 'ironic', {}, {}
ironic_swift_tempurl_key = ironic_hash['swift_tempurl_key']

ENV['OS_TENANT_NAME']="#{tenant_name}"
ENV['OS_USERNAME']="#{user_name}"
ENV['OS_PASSWORD']="#{glanced['user_password']}"
ENV['OS_AUTH_URL']="http://#{auth_addr}:5000/v2.0"
ENV['OS_ENDPOINT_TYPE'] = "#{endpoint_type}"
ENV['OS_REGION_NAME']="#{region_name}"


command = <<-EOF
/usr/bin/swift post -m 'Temp-URL-Key:#{ironic_swift_tempurl_key}'
EOF
5.times.each do |retries|
  sleep 10 if retries > 0
  stdout = `#{command}`
  return_code = $?.exitstatus
  puts stdout
  exit 0 if return_code == 0
end

puts "Secret key registration have FAILED!"
exit 1
