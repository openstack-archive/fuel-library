require 'hiera'
require 'test/unit'

def ping(host)
  `ping -q -c 1 -W 3 '#{host}'`
  $?.exitstatus == 0
end

def hiera
  return $hiera if $hiera
  $hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
end

def public_vip
  return $public_vip if $public_vip
  $public_vip = hiera.lookup 'public_vip', nil, {}
  $public_vip += '0'
end

def management_vip
  return $management_vip if $management_vip
  $management_vip = hiera.lookup 'management_vip', nil, {}
end

def deployment_mode
  return $deployment_mode if $deployment_mode
  $deployment_mode = hiera.lookup 'deployment_mode', nil, {}
end

def is_ha?
  %w(ha ha_compact).include? deployment_mode
end

class VirtualIPsPostTest < Test::Unit::TestCase

  def test_public_vip_ping
    assert ping(public_vip), "Could not ping the public vip '#{public_vip}'!" if is_ha?
  end

  def test_management_vip_ping
    assert ping(management_vip), "Could not ping the management vip '#{management_vip}'!" if is_ha?
  end

end
