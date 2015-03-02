require 'test/unit'
require 'socket'

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
    s = TCPSocket.open(host, port)
    s.close
  rescue
    return false
  end
  true
end

def radosgw_backend_online?
  test_connection('localhost', '6780')
end

PROCESSES = %w(
radosgw
)

class RadosgwPostTest < Test::Unit::TestCase
  def self.create_tests
    PROCESSES.each do |process|
      method_name = "test_iprocess_#{process}_running"
      define_method method_name do
        assert process_tree.find { |pid, proc| proc[:cmd].include? process }, "Process '#{process}' is not running!"
      end
    end
  end

  def test_radosgw_backend_online
    assert radosgw_backend_online?, 'Can not connect to radoswg on this host!'
  end
end

RadosgwPostTest.create_tests
