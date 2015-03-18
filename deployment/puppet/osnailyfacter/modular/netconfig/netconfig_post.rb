require File.join File.dirname(__FILE__), '../test_common.rb'

class NetconfigPostTest < Test::Unit::TestCase

  def test_management_ip_present
    ip = TestCommon::Settings.node['internal_address']
    assert TestCommon::Network.ips.include?(ip), 'Management address is not set!'
  end

  def test_public_ip_present
    if %w(controller primary-controller).include? TestCommon::Settings.role
      ip = TestCommon::Settings.node['public_address']
      assert TestCommon::Network.ips.include?(ip), 'Public address is not set!'
    end
  end

  def test_storage_ip_present
    ip = TestCommon::Settings.node['storage_address']
    assert TestCommon::Network.ips.include?(ip), 'Storage address is not set!'
  end

  def test_can_ping_the_master_node
    ip = TestCommon::Settings.master_ip
    assert ping(ip), 'Cannot ping the master node!'
  end

end
