module Process
  @process_tree = nil

  # get ps from shell command
  # @return [String]
  def ps
    `ps haxo pid,ppid,cmd`
  end

  # same as process_tree but reset mnemoization
  # @return [Hash<Integer => Hash<Symbol => String,Integer>>]
  def process_tree_with_renew
    @process_tree = nil
    process_tree
  end

  # build process tree from process list
  # @return [Hash<Integer => Hash<Symbol => String,Integer>>]
  def process_tree
    return @process_tree if @process_tree
    @process_tree = {}
    ps.split("\n").each do |p|
      f = p.split
      pid = f.shift.to_i
      ppid = f.shift.to_i
      cmd = f.join ' '

      # create entry for this pid if not present
      @process_tree[pid] = {
          :children => []
      } unless @process_tree.key? pid

      # fill this entry
      @process_tree[pid][:ppid] = ppid
      @process_tree[pid][:pid] = pid
      @process_tree[pid][:cmd] = cmd

      # create entry for parent process if not present
      @process_tree[ppid] = {
          :children => []
      } unless @process_tree.key? ppid

      # fill parent's children
      @process_tree[ppid][:children] << pid
    end
    @process_tree
  end

  # kill selected pid or array of them
  # @param pids [Integer,String] Pids to kill
  # @param signal [Integer,String] Which signal?
  # @param recursive [TrueClass,FalseClass] Kill children too?
  # @return [TrueClass,FalseClass] Was the signal sent? Process may still be present even on success.
  def kill_pids(pids, signal = 9, recursive = true)
    pids = Array pids

    pids_to_kill = pids.inject([]) do |all_pids, pid|
      pid = pid.to_i
      if recursive
        all_pids + get_children_pids(pid)
      else
        all_pids << pid
      end
    end

    pids_to_kill.uniq!
    pids_to_kill.sort!

    return false unless pids_to_kill.any?
    log "Kill these pids: #{pids_to_kill.join ', '} with signal #{signal}"
    run "kill -#{signal} #{pids_to_kill.join ' '}"
  end

  # recursion to find all children pids
  # @return [Array<Integer>]
  def get_children_pids(pid)
    pid = pid.to_i
    unless process_tree.key? pid
      log "No such pid: #{pid}"
      return []
    end
    process_tree[pid][:children].inject([pid]) do |all_children_pids, child_pid|
      all_children_pids + get_children_pids(child_pid)
    end
  end

  # filter pids which cmd match regexp
  # @param regexp <Regexp> Search pids by this regexp
  # @return [Hash<Integer => Hash<Symbol => String,Integer>>]
  def pids_by_regexp(regexp)
    matched = {}
    process_tree.each do |pid,process|
      matched[pid] = process if process[:cmd] =~ regexp
    end
    matched
  end

  # kill pids that match regexp
  # @param regexp <Regexp>
  # @return <TrueClass,FalseClass>
  def kill_pids_by_regexp(regexp)
    pids = pids_by_regexp(regexp).keys
    kill_pids pids
  end
end