require File.join File.dirname(__FILE__), 'pacemaker.rb'
require 'rubygems'
require 'pry'

class PacemakerConsole
  include Pacemaker

  def initialize
    self.raw_cib_file = 'cib.xml'
    binding.pry
  end
end

PacemakerConsole.new