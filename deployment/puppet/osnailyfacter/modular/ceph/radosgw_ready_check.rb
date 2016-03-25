#!/usr/bin/env ruby
require 'hiera'

ENV['LANG'] = 'C'
$hiera = Hiera.new(:config => '/etc/hiera.yaml')

def ready_rgw
  public_rgw_address = $hiera.lookup('public_vip', nil, {})
  public_rgw_port = '8080'
  stdout = `curl -s -o /dev/null -w "%{http_code}" http://#{public_rgw_address}:#{public_rgw_port}`
  return true if $?.exitstatus == 0 and stdout == '200'
  puts "Error: exit code #{$?.exitstatus}, HTTP code #{stdout}"
  return false
end

# check if radosgw is ready
def wait_for_ready_rgw
  60.times do |try|
    puts "try #{try}"
    return if ready_rgw
    sleep 10
  end
  raise "RadosGW is not ready yet!"
end

wait_for_ready_rgw
