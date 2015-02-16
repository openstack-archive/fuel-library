require 'hiera'
require 'test/unit'

def process_tree
  return $process_tree if $process_tree
  $process_tree = {}
  ps = `ps haxo pid,ppid,cmd`
  ps.split("\n").each do |p|
    f = p.split
    pid = f.shift.to_i
    ppid = f.shift.to_i
    cmd = f.join ' '

    # create entry for this pid if not present
    $process_tree[pid] = {
        :children => []
    } unless $process_tree.key? pid

    # fill this entry
    $process_tree[pid][:ppid] = ppid
    $process_tree[pid][:pid] = pid
    $process_tree[pid][:cmd] = cmd

    unless ppid == 0
      # create entry for parent process if not present
      $process_tree[ppid] = {
          :children => [],
          :cmd => '',
      } unless $process_tree.key? ppid

      # fill parent's children
      $process_tree[ppid][:children] << pid
    end
  end
  $process_tree
end

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

def haproxy_stats_url
  ip = management_vip
  ip = controller_node_address unless ip
  raise 'Could not get internal address!' unless ip
  port = 10000
  "http://#{ip}:#{port}/;csv"
end

def url_accessible?(url)
  `curl --fail '#{url}' 1>/dev/null 2>/dev/null`
  $?.exitstatus == 0
end

class ClusterHaproxyPostTest < Test::Unit::TestCase
  def test_haproxy_config_present
    assert File.file?('/etc/haproxy/haproxy.cfg'), 'No haproxy config file!'
  end

  def test_haproxy_is_running
    assert process_tree.find { |pid, proc| proc[:cmd].include? '/usr/sbin/haproxy' }, 'Haproxy is not running!'
  end

  def test_haproxy_stats_accessible
    assert url_accessible?(haproxy_stats_url), "Cannot connect to the HAProxy stats url '#{haproxy_stats_url}'!"
  end
end
