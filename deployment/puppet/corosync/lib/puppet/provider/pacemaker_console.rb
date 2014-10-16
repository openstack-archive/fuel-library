require 'rubygems'
require 'pry'
require 'puppet'
require 'puppet/util/execution'
require File.join File.dirname(__FILE__), 'pacemaker.rb'

class PacemakerConsole
  include Pacemaker

  class << Puppet::Util::Execution
    def debug(msg)
      puts msg
    end
  end

  attr_accessor :dry_run

  def pcs(*args)
    command = ['pcs'] + Array(args)
    if dry_run
      puts "Run: #{command.join ' '}"
    else
      Puppet::Util::Execution.execute command
    end
  end

  def cibadmin(*args)
    command = ['cibadmin'] + Array(args)
    if dry_run
      puts "Run: #{command.join ' '}"
    else
      Puppet::Util::Execution.execute command
    end
  end

  def initialize
    test_cib_file = File.join File.dirname(__FILE__), 'cib.xml'
    if File.exists? test_cib_file
      self.dry_run = true
      self.raw_cib_file = test_cib_file
    end
    binding.pry
  end
end

PacemakerConsole.new
