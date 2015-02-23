#!/usr/bin/env ruby
require 'rubygems'
require 'hiera'
require 'timeout'

RETRY_COUNT   = 5
RETRY_WAIT    = 1
RETRY_TIMEOUT = 10

def get_nova_creds(hiera)
  creds = hiera.lookup 'nova', {}, {}
  raise 'Invalid nova creds!' if creds['user_password'].nil?
  creds
end

def get_auth_url(hiera)
  management_vip = hiera.lookup 'management_vip', '', {}
  raise 'Invalid nova creds!' if management_vip.empty?
  "http://#{management_vip}:5000/v2.0/"
end

def get_cli_auth_params(url, pass, user='nova', tenant='services')
  "--os-username #{user} --os-password #{pass} --os-tenant-name #{tenant} --os-auth-url #{url}"
end

def get_node_names(hiera)
  node = hiera.lookup 'node', [], {}
  raise 'Invalid node name!' if node[0].nil? or node[0]['name'].nil? or node[0]['fqdn'].nil?
  [node[0]['name'], node[0]['fqdn']]
end

def enable_compute(hiera, names, creds)
  puts "Enable compute service with nova creds"
  cli_auth_params = get_cli_auth_params(url=get_auth_url(hiera), pass=creds['user_password'])

  # start stopped by the puppet nova-compute service and mask its exit code to be 0 as it might be
  # already running for some reason
  command_start = "service nova-compute start || service openstack-nova-compute start || true"
  # issue an enable command both for node's shortname and FQDN
  command_enable = "nova #{cli_auth_params} service-enable #{names[0]} nova-compute || nova #{cli_auth_params} service-enable #{names[1]} nova-compute"
  RETRY_COUNT.times do |n|
    begin
      Timeout::timeout(RETRY_TIMEOUT) do
        system command_start
        system command_enable
        return if $?.exitstatus == 0
      end
    rescue Timeout::Error
      nil
    end
    puts "Error! Retry: #{n + 1}"
    sleep RETRY_WAIT
  end
  fail "Could not enable compute service!"
end

def get_compute_state(hiera, names, creds)
  cli_auth_params = get_cli_auth_params(url=get_auth_url(hiera), pass=creds['user_password'])
  # filter nova service-list output by compute service and node's shortname (FQDN always includes a shortname as well)
  command = "nova #{cli_auth_params} service-list | awk '/nova-compute.*#{names[0]}/ {print $10}'"
  RETRY_COUNT.times do |n|
    begin
      Timeout::timeout(RETRY_TIMEOUT) do
        status = `#{command}`.chomp
        return status if $?.exitstatus == 0
      end
    rescue Timeout::Error
      nil
    end
    puts "Error! Retry: #{n + 1}"
    sleep RETRY_WAIT
  end
  fail "Could not get compute service state!"
end

##############

hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
creds = get_nova_creds(hiera)
names = get_node_names(hiera)
current_service_state = get_compute_state(hiera, names, creds)

puts "Current compute service state: '#{current_service_state}'"
enable_compute(hiera, names, creds) unless current_service_state == 'enabled'
puts "Compute service new state is: '#{get_compute_state(hiera, names, creds)}'"
exit 0
