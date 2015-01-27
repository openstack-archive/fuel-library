require 'rubygems'
require 'puppet'
require File.join File.dirname(__FILE__), '../provider/pacemaker_common'

# This file is like 'pcs status'. You can use it to view
# the status of the cluster as this library sees it
# using the debug output function.
#
# You can give it a dumped cib XML file for the first argument
# id you want to debug the code without Pacemaker running.

class Puppet::Provider::Pacemaker_common
  def debug(msg)
    puts msg
  end
  alias :info :debug
  def cibadmin(*args)
    command = ['cibadmin'] + args
    if Puppet::Util::Execution.respond_to? :execute
      Puppet::Util::Execution.execute command
    else
      Puppet::Util.execute command
    end
  end
end

common = Puppet::Provider::Pacemaker_common.new
if $ARGV[0] and File.exists? $ARGV[0]
  common.cib_file = $ARGV[0]
end
puts common.cluster_debug_report

