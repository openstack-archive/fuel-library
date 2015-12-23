module Noop
  class Task
    def initialize(spec, hiera=nil, facts=nil)
      self.file_name_spec = spec
      self.file_name_hiera = hiera
      self.file_name_facts = facts
      @parallel = false
    end

    attr_accessor :parallel

    def parallel_run?
      parallel
    end

    def debug(message)
      Noop::Config.log.debug message
    end

    def to_s
      "Task[#{file_base_spec}]"
    end

    def inspect
      message = "#{self}{"
      message += "Hiera: #{file_base_hiera} Facts: #{file_base_facts}"
      if parallel_run?
        message += " Pid: #{pid}" if pid
        message += " Thread: #{thread}" if thread
      end
      message += " Success: #{success}" unless success.nil?
      message + '}'
    end
  end
end
