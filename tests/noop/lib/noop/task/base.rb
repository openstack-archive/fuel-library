module Noop
  class Task
    def initialize(spec, hiera=nil, facts=nil)
      self.file_name_spec = spec
      self.file_name_hiera = hiera
      self.file_name_facts = facts
    end

    def to_s
      "Task[#{file_name_spec}]"
    end

    def inspect
      to_s
    end
  end
end
