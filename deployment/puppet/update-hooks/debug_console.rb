require 'rubygems'
require 'pry'

require File.join(File.dirname(__FILE__), 'lib/base')
require File.join(File.dirname(__FILE__), 'lib/service')
require File.join(File.dirname(__FILE__), 'lib/process')
require File.join(File.dirname(__FILE__), 'lib/pacemaker')
require File.join(File.dirname(__FILE__), 'lib/package')
require File.join(File.dirname(__FILE__), 'lib/mysql')
require File.join(File.dirname(__FILE__), 'lib/migration')

class DebugConsole
  include Base
  include Service
  include Process
  include Pacemaker
  include Package
  include MySQL
  include Migration

  def initialize
    binding.pry
  end
end

DebugConsole.new