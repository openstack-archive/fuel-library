#!/usr/bin/env ruby
# this script verifies that keystone has
# been successfully installed using the instructions
# found here: http://keystone.openstack.org/configuration.html

require 'open3'
require 'fileutils'
require 'puppet'

get_token = %(curl -d '{"auth":{"passwordCredentials":{"username": "admin", "password": "ChangeMe"}}}' -H "Content-type: application/json" http://localhost:35357/v2.0/tokens)
token = nil
Open3.popen3(get_token) do |stdin, stdout, stderr|
  begin
    stdout = stdout.read
    puts "Response from token request:#{stdout}"
    token = PSON.load(stdout)["access"]["token"]["id"]
  rescue Exception => e
    puts "Could not retrieve token from response, this sh*t is borked :( : details: #{e}"
    exit 1
  end
end

if token
  puts "We were able to retrieve a token"
end




