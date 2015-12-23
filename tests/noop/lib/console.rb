require_relative 'noop/config'
require_relative 'noop/task'
require_relative 'noop/manager'
require_relative 'noop/utils'

manager = Noop::Manager.new

require 'pry'
manager.pry
