require 'hiera'
require 'test/unit'
require 'open-uri'
require 'socket'

def hiera
  return $hiera if $hiera
  $hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
end

def management_vip
  return $management_vip if $management_vip
  $management_vip = hiera.lookup 'management_vip', nil, {}
end

def hostname
  return $hostname if $hostname
  $hostname = Socket.gethostname.split('.').first
end

def controller_node_address
  return $controller_node_address if $controller_node_address
  $controller_node_address = hiera.lookup 'controller_node_address', nil, {}
end

def haproxy_stats_url
  ip = management_vip
  ip = controller_node_address unless ip
  raise 'Could not get internal address!' unless ip
  port = 10000
  "http://#{ip}:#{port}/;csv"
end

def csv
  return $csv if $csv
  begin
    url = open(haproxy_stats_url)
    csv = url.read
  rescue
    nil
  end
  return nil unless csv and not csv.empty?
  $csv = csv
end

def keystone_backends_online?
  raise 'Could not get CSV from HAProxy stats!' unless csv
  status = false
  csv.split("\n").each do |line|
    next unless line.start_with? 'keystone'
    next unless line.include? 'BACKEND'
    puts "DEBUG: #{line}"
    fields = line.split(',')
    status ||= fields[17].eql? 'UP'
  end
  status
end

class OpenStackNetworkComputePreTest < Test::Unit::TestCase
  def test_keystone_backends_are_online
    assert keystone_backends_online?, 'Haproxy keystone backend is down!'
  end
end
