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

def is_memcached_accessible?
  # TODO: write test to check connectivity to memcached port on localhost
  true
end

PROCESSES = %w(
memcached
)

class HorizonPreTest < Test::Unit::TestCase
  def self.create_tests
    PROCESSES.each do |process|
      method_name = "test_iprocess_#{process}_running"
      define_method method_name do
        assert process_tree.find { |pid, proc| proc[:cmd].include? process }, "Process '#{process}' is not running!"
      end
    end
  end

  def test_memcached_is_accessible
    assert is_memcached_accessible?, 'Memcached is not accessible!'
  end
end

HorizonPreTest.create_tests
