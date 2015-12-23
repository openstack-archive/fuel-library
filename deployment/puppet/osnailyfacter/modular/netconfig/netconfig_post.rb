require File.join File.dirname(__FILE__), '../test_common.rb'

class NetconfigPostTest < Test::Unit::TestCase
  def node
    TestCommon::Settings.nodes.each do |node|
      next unless node['fqdn'] == TestCommon::Settings.fqdn
      return node
    end
  end

  def test_management_ip_present
    ip = node['internal_address']
    assert TestCommon::Network.ips.include?(ip), 'Management address is not set!'
  end

  def test_public_ip_present
    if %w(controller primary-controller).include? TestCommon::Settings.role
      ip = node['public_address']
      assert TestCommon::Network.ips.include?(ip), 'Public address is not set!'
    end
  end

  def test_storage_ip_present
    ip = node['storage_address']
    assert TestCommon::Network.ips.include?(ip), 'Storage address is not set!'
  end

  def test_can_ping_the_default_router_on_controller
    return unless %w(controller primary-controller).include? TestCommon::Settings.role
    ip = TestCommon::Network.default_router
    assert TestCommon::Network.ping?(ip), "Cannot ping the default router '#{ip}'!"
  end

  def test_can_ping_the_master_node
    ip = TestCommon::Settings.master_ip
    assert TestCommon::Network.ping?(ip), "Cannot ping the master node '#{ip}'!"
  end

  def processor_count
    File.read('/proc/cpuinfo').split("\n").count { |line| line.start_with? 'processor' }
  end

  def hex_mask
    return @hex_mask if @hex_mask
    @hex_mask = ((2 ** processor_count) -1 ).to_s(16)
  end

  def rps_cpus
    Dir.glob('/sys/class/net/eth*/queues/rx-*/rps_cpus')
  end

  def test_rps_cpus_set
    rps_cpus.each do |node|
      assert File.read(node).chomp.end_with?(hex_mask), "Sysfs node: '#{node}' is not '#{hex_mask}'!"
    end
  end

  def test_rps_cpus_config
    assert File.exists?('/etc/sysfs.d/rps_cpus.conf'), 'RPS_CPUS sysfs config is missing!'
    rps_cpus.each do |line|
      line.gsub! %r(/sys/), ''
      line = "#{line} = #{hex_mask}"
      assert TestCommon::Config.has_line?('/etc/sysfs.d/rps_cpus.conf', line), "Line '#{line}' is missing in the rps_cpus.conf!"
    end
  end

end
