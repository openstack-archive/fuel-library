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

def pacemaker_online?
  `timeout 5 cibadmin -Q`
  $?.exitstatus == 0
end

PROCESSES = %w(
crmd
pengine
attrd
stonithd
cib
pacemakerd
corosync
)

class ClusterPostTest < Test::Unit::TestCase
  def self.create_tests
    PROCESSES.each do |process|
      method_name = "test_iprocess_#{process}_running"
      define_method method_name do
        assert process_tree.find { |pid, proc| proc[:cmd].include? process }, "Process '#{process}' is not running!"
      end
    end
  end

  def test_pacemaker_is_online
    assert pacemaker_online?, 'Could not query Pacemaker CIB!'
  end
end

ClusterPostTest.create_tests
