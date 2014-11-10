require 'rubygems'
require 'puppet'
require 'pry'
require File.join File.dirname(__FILE__), 'pacemaker_common'


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
  def initialize
    cib_reset
    binding.pry
  end
  def debug(msg)
    puts msg
  end
  alias :info :debug
end

if $ARGV[0] and File.exists? $ARGV[0]
  class Puppet::Provider::Pacemaker_common
    def raw_cib
      File.read $ARGV[0]
    end
  end
end

Puppet::Provider::Pacemaker_common.new
