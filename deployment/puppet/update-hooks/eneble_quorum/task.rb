#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), '../lib/base')
require File.join(File.dirname(__FILE__), '../lib/pacemaker')

class Task
  include Base
  include Pacemaker

  def execute
    @dry_run = false
    quorum_policy 'stop'
  end

end

if __FILE__ == $0
  me = Task.new
  me.execute
end
