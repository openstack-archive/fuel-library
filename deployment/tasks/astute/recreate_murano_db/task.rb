#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), '../lib/base')
require File.join(File.dirname(__FILE__), '../lib/mysql')
require File.join(File.dirname(__FILE__), '../lib/migration')

class Task
  include Base
  include MySQL
  include Migration

  def execute
    @dry_run = false
    recreate_murano_database
  end

end

if __FILE__ == $0
  me = Task.new
  me.execute
end
