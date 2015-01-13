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

class HeatPostTest < Test::Unit::TestCase

  def test_heat_is_running
    assert process_tree.find { |pid, proc| proc[:cmd].include? 'heat' }, 'Heat is not running!'
  end

end
