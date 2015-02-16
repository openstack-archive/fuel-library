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

class NetconfigPostTest < Test::Unit::TestCase

  def test_management_ip_present
    ip = nodes.find { |node| node['fqdn'] == fqdn }['internal_address']
    assert ips.include?(ip), 'Management address is not set!'
  end

  def test_public_ip_present
    ip = nodes.find { |node| node['fqdn'] == fqdn }['public_address']
    assert ips.include?(ip), 'Public address is not set!' unless role == 'compute'
  end

  def test_storage_ip_present
    ip = nodes.find { |node| node['fqdn'] == fqdn }['storage_address']
    assert ips.include?(ip), 'Storage address is not set!'
  end

end
