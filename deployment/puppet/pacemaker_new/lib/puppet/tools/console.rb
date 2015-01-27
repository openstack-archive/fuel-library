require 'rubygems'
require 'puppet'
require 'pry'
require File.join File.dirname(__FILE__), '../provider/pacemaker.rb'

# This console can be used to debug the pacemaker library
# and its methods or for manual control over the cluster.
#
# It requires 'pry' gem to be installed.
#
# You can give it a dumped cib XML file for the first argument
# id you want to debug the code without Pacemaker running.

class Puppet::Provider::Pacemaker_common
  [:cibadmin, :crm_attribute, :crm_node, :crm_resource, :crm_attribute, :crm_shadow].each do |tool|
    define_method(tool) do |*args|
      command = [tool.to_s] + args
      if Puppet::Util::Execution.respond_to? :execute
        Puppet::Util::Execution.execute command
      else
        Puppet::Util.execute command
      end
    end
  end
end

class Puppet::Provider::Pacemaker_common
  def debug(msg)
    puts msg
  end
  alias :info :debug
end

common = Puppet::Provider::Pacemaker_common.new
if $ARGV[0] and File.exists? $ARGV[0]
  common.cib_file = $ARGV[0]
end
common.pry

