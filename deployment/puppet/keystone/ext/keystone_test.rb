#!/usr/bin/env ruby
# this script verifies that keystone has
# been successfully installed using the instructions
# found here: http://keystone.openstack.org/configuration.html

begin
  require 'rubygems'
rescue
  puts 'Could not require rubygems. This assumes puppet is not installed as a gem'
end
require 'open3'
require 'fileutils'
require 'puppet'

username='admin'
password='admin_password'
# required to get a real services catalog
tenant='openstack'

# shared secret
service_token='service_token'

def run_command(cmd)
  Open3.popen3(cmd) do |stdin, stdout, stderr|
    begin
      stdout = stdout.read
      puts "Response from token request:#{stdout}"
      return stdout
    rescue Exception => e
      puts "Request failed, this sh*t is borked :( : details: #{e}"
      exit 1
    end
  end
end

puts `puppet apply -e "package {curl: ensure => present }"`

get_token = %(curl -d '{"auth":{"passwordCredentials":{"username": "#{username}", "password": "#{password}"}}}' -H "Content-type: application/json" http://localhost:35357/v2.0/tokens)
token = nil

puts "Running auth command: #{get_token}"
token = PSON.load(run_command(get_token))["access"]["token"]["id"]

if token
  puts "We were able to retrieve a token"
  puts token
  verify_token = "curl -H 'X-Auth-Token: #{service_token}' http://localhost:35357/v2.0/tokens/#{token}"
  puts 'verifying token'
  run_command(verify_token)
  ['endpoints', 'tenants', 'users'].each do |x|
    puts "getting #{x}"
    get_keystone_data = "curl -H 'X-Auth-Token: #{service_token}' http://localhost:35357/v2.0/#{x}"
    run_command(get_keystone_data)
  end
end
