#!/usr/bin/env ruby
# this script verifies that keystone has
# been successfully installed using the instructions
# found here: http://keystone.openstack.org/configuration.html
# and can use the v3 api http://developer.openstack.org/api-ref-identity-v3.html

begin
  require 'rubygems'
rescue
  puts 'Could not require rubygems. This assumes puppet is not installed as a gem'
end
require 'open3'
require 'fileutils'
require 'puppet'
require 'pp'

username='admin'
password='a_big_secret'
# required to get a real services catalog
project='openstack'
user_domain='admin'
project_domain='admin'

# shared secret
service_token='admin_token'

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
get_token = %(curl -D - -d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"domain":{"name":"#{user_domain}"},"name":"#{username}","password": "#{password}"}}},"scope":{"project":{"domain":{"name":"#{project_domain}"},"name": "#{project}"}}}}' -H "Content-type: application/json" http://localhost:35357/v3/auth/tokens)
token = nil

puts "Running auth command: #{get_token}"
rawoutput = run_command(get_token)
if rawoutput =~ /X-Subject-Token: ([\w]+)/
  token = $1
else
  puts "No token in output! #{rawoutput}"
  exit 1
end

if token
  puts "We were able to retrieve a token"
  puts token
  verify_token = "curl -H 'X-Auth-Token: #{service_token}' 'X-Subject-Token: #{token}' http://localhost:35357/v3/auth/tokens"
  puts 'verifying token'
  run_command(verify_token)
  ['endpoints', 'projects', 'users'].each do |x|
    puts "getting #{x}"
    get_keystone_data = "curl -H 'X-Auth-Token: #{token}' http://localhost:35357/v3/#{x}"
    pp PSON.load(run_command(get_keystone_data))
  end
end
