require 'irb'
require 'colorize'

module Noop
  class Manager
    def output_task_status(task)
      line = task_status(task)
      line += "#{task.file_base_spec.to_s.ljust max_length_spec + 1}"
      line += "#{task.file_base_facts.to_s.ljust max_length_facts + 1}"
      line += "#{task.file_base_hiera.to_s.ljust max_length_hiera + 1}"
      line
    end

    def task_status(task)
      return 'PENDING'.ljust(8).colorize :blue if task.success.nil?
      if task.success
        'SUCCESS'.ljust(8).colorize :green
      else
        'FAILED'.ljust(8).colorize :red
      end
    end

    def max_length_spec
      return @max_length_spec if @max_length_spec
      @max_length_spec = task_list.map do |task|
        task.file_base_spec.to_s.length
      end.max
    end

    def max_length_hiera
      return @max_length_hiera if @max_length_hiera
      @max_length_hiera = task_list.map do |task|
        task.file_base_hiera.to_s.length
      end.max
    end

    def max_length_facts
      return @max_length_facts if @max_length_facts
      @max_length_facts = task_list.map do |task|
        task.file_base_facts.to_s.length
      end.max
    end

    def task_report
      task_list.each do |task|
        puts output_task_status task
      end
    end
  end
end
