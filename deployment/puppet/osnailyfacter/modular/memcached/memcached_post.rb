require 'hiera'
require 'test/unit'
require 'socket'
require 'timeout'

def hiera
  return $hiera if $hiera
  $hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
end

def internal_address
  return $internal_address if $internal_address
  $internal_address = hiera.lookup 'internal_address', nil, {}
end

def public_address
  return $public_address if $public_address
  $public_address = hiera.lookup 'public_address', nil, {}
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

def test_connection(host, port)
  begin
    Timeout::timeout( 3 ) do
      s = TCPSocket.open(host, port)
      s.close
    end
  rescue
    raise Errno::ECONNREFUSED
  end
  true
end

def memcached_backend_online?
  test_connection(internal_address, '11211')
end

def memcached_backend_listen_public?
  test_connection(public_address, '11211')
end

PROCESSES = %w(
memcached
)

class MemcachedPostTest < Test::Unit::TestCase
  def self.create_tests
    PROCESSES.each do |process|
      method_name = "test_iprocess_#{process}_running"
      define_method method_name do
        assert process_tree.find { |pid, proc| proc[:cmd].include? process }, "Process '#{process}' is not running!"
      end
    end
  end

  def test_memcached_backend_online
    assert_nothing_raised do
      assert memcached_backend_online?, 'Can not connect to memcached on this host!'
    end
  end

  def test_memcached_backend_dont_listen_public
    assert_raise Errno::ECONNREFUSED do
      memcached_backend_listen_public?
    end
  end
end

MemcachedPostTest.create_tests
