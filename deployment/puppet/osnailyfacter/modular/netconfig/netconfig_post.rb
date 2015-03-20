require 'hiera'
require 'test/unit'

def ips
  return $ips if $ips
  ip_out = `ip addr`
  return unless $?.exitstatus == 0
  ips = []
  ip_out.split("\n").each do |line|
    if line =~ /\s+inet\s+([\d\.]*)/
      ips << $1
    end
  end
  $ips = ips
end

def router
  return $router if $router
  routes = `ip route`
  return unless $?.exitstatus == 0
  routes.split("\n").each do |line|
    if line =~ /^default via ([\d\.]*)/
      return $router = $1
    end
  end
  nil
end

def ping(host)
  `ping -q -c 1 -W 3 '#{host}'`
  $?.exitstatus == 0
end

def hiera
  return $hiera if $hiera
  $hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
end

def fqdn
  return $fqdn if $fqdn
  $fqdn = hiera.lookup 'fqdn', nil, {}
end

def nodes
  return $nodes if $nodes
  $nodes = hiera.lookup 'nodes', [], {}
end

def role
  return $role if $role
  $role = hiera.lookup 'role', nil, {}
end

def master_ip
  return $master_ip if $master_ip
  $master_ip = hiera.lookup 'master_ip', nil, {}
end

class NetconfigPostTest < Test::Unit::TestCase

  def test_management_ip_present
    ip = nodes.find { |node| node['fqdn'] == fqdn }['internal_address']
    assert ips.include?(ip), 'Management address is not set!'
  end

  def test_public_ip_present
    if %w(controller primary-controller).include? role
      ip = nodes.find { |node| node['fqdn'] == fqdn }['public_address']
      assert ips.include?(ip), 'Public address is not set!'
    end
  end

  def test_storage_ip_present
    ip = nodes.find { |node| node['fqdn'] == fqdn }['storage_address']
    assert ips.include?(ip), 'Storage address is not set!'
  end

  def test_can_ping_the_master_node
    assert ping(master_ip), 'Cannot ping the master node!'
  end

  def test_can_ping_the_default_router_on_controller
    if %w(controller primary-controller).include? role
      assert ping(router), 'Cannot ping the default router!'
    end
  end

end
