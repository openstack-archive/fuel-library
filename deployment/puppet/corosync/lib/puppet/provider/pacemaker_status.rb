require 'rubygems'
require 'puppet'
require File.join File.dirname(__FILE__), 'pacemaker_common'

class Puppet::Provider::Pacemaker_common
  def cibadmin(*args)
    command = ['cibadmin'] + args
    if Puppet::Util::Execution.respond_to? :execute
      Puppet::Util::Execution.execute command
    else
      Puppet::Util.execute command
    end
  end
  def initialize
    cib_reset
    puts cluster_debug_report
  end
end

Puppet::Provider::Pacemaker_common.new