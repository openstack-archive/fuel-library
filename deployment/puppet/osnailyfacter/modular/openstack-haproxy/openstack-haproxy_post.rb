require 'hiera'
require 'test/unit'
require 'open-uri'

def hiera
  return $hiera if $hiera
  $hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
end

def management_vip
  return $management_vip if $management_vip
  $management_vip = hiera.lookup 'management_vip', nil, {}
end

def controller_node_address
  return $controller_node_address if $controller_node_address
  $controller_node_address = hiera.lookup 'controller_node_address', nil, {}
end

def sahara_enabled?
  return $sahara_enabled if $sahara_enabled
  sahara = hiera.lookup 'sahara', {}, {}
  $sahara_enabled = sahara.fetch 'enabled', false
end

def murano_enabled?
  return $murano_enabled if $murano_enabled
  murano = hiera.lookup 'murano', {}, {}
  $murano_enabled = murano.fetch 'enabled', false
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

def haproxy_backends
  return $backends if $backends
  raise 'Could not get CSV from HAProxy stats!' unless csv
  backends = []
  csv.split("\n").each do |line|
    next if line.start_with? '#'
    next unless line.include? 'BACKEND'
    backend = line.split(',').first
    backends << backend
  end
  $backends = backends
end

def expected_backends
  return $expected_backends if $expected_backends
  backends = %w(
    Stats
    horizon
    keystone-1
    keystone-2
    nova-api-1
    nova-api-2
    nova-metadata-api
    cinder-api
    glance-api
    neutron
    glance-registry
    rabbitmq
    mysqld
    swift
    heat-api
    heat-api-cfn
    heat-api-cloudwatch
    nova-novncproxy
  )
  backends += %w(sahara) if sahara_enabled?
  backends += %w(murano murano_rabbitmq) if murano_enabled?
  $expected_backends = backends
end

class OpenstackHaproxyPostTest < Test::Unit::TestCase
  def self.create_tests
    expected_backends.each do |backend|
      method_name = "test_backend_#{backend}_present"
      define_method method_name do
        assert haproxy_backends.include?(backend), "There is no '#{backend}' HAProxy backend!"
      end
    end
  end
end

OpenstackHaproxyPostTest.create_tests
