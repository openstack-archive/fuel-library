require 'logger'

module Noop
  module Config
    def self.log
      return @log if @log
      @log = Logger.new STDOUT
      @log.level = Logger::DEBUG
      @log
    end
  end
end
