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

def horizon_backend_online?
  raise 'Could not get CSV from HAProxy stats!' unless csv
  status = 'DOWN'
  csv.split("\n").each do |line|
    next unless line.start_with? 'horizon'
    next unless line.include? hostname
    puts "DEBUG: #{line}"
    fields = line.split(',')
    status = fields[17]
  end
  status == 'UP'
end

class HorizonPostTest < Test::Unit::TestCase
  def test_horizon_backend_online
    assert horizon_backend_online?, 'Haproxy horizon backend is down on this node!'
  end
end

