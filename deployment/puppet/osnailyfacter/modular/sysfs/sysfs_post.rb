require File.join File.dirname(__FILE__), '../test_common.rb'

class SysfsPostTest < Test::Unit::TestCase

  def processor_count
    File.read('/proc/cpuinfo').split("\n").count { |line| line.start_with? 'processor' }
  end

  def hex_mask
    return @hex_mask if @hex_mask
    @hex_mask = ((2 ** processor_count) -1 ).to_s(16)
  end

  def rps_cpus
    Dir.glob('/sys/class/net/*/queues/rx-*/rps_cpus').reject { |node| node.start_with? '/sys/class/net/lo' }
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
