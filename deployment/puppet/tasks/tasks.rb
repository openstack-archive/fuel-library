#!/usr/bin/env ruby

require 'pathname'

class Pathname
  def puppet_class_name
    "task::#{self.sub_ext('').to_s.gsub('/', '::')}"
  end
end

module Tasks
  def self.file_path_script
    Pathname.new(__FILE__).expand_path
  end

  def self.dir_path_root
    file_path_script.parent.parent
  end

  def self.dir_path_modular
    dir_path_root + Pathname.new('osnailyfacter/modular')
  end

  def self.dir_path_tasks_manifests
    dir_path_root + Pathname.new('tasks/manifests/')
  end

  def self.all_modular_tasks
    modular_tasks = []
    dir_path_modular.find do |task|
      next unless File.file? task
      next unless task.to_s.end_with? '.pp'
      task_name = Pathname.new(task).relative_path_from dir_path_modular
      modular_tasks << task_name
    end
    modular_tasks
  end

  def self.purge_tasks
    dir_path_tasks_manifests.find do |task|
      next unless File.file? task
      next unless task.to_s.end_with? '.pp'
      puts "Remove: #{task}"
      File.unlink task
    end
  end

  def self.indent_content(content)
    content.split("\n").map do |line|
      if line == ''
        line
      else
        '  '  + line
      end
    end.join "\n"
  end

  def self.generate_wrapper_class(task)
    task_path = dir_path_modular + task
    content = File.read task_path.to_s
    fail "Could not read the task file: #{task_path}!" unless content
    content = indent_content content
    "class #{task.puppet_class_name} {\n\n#{content}\n\n}"
  end

  def self.generate_new_modular_task(task)
    "notice('INCLUDE: #{task.puppet_class_name}')\n\ninclude ::#{task.puppet_class_name}"
  end

  def self.create_new_wrapped_tasks
    all_modular_tasks.each do |task|
      content = generate_wrapper_class task
      next unless content
      path = dir_path_tasks_manifests + task
      next unless path
      path.dirname.mkpath
      puts "Writing a new wrapped task: #{path}"
      File.open(path.to_s, 'w') do |file|
        file.puts content
      end
    end
  end

  def self.create_new_modular_tasks
    all_modular_tasks.each do |task|
      content = generate_new_modular_task task
      path = task.to_s
      path += '.new'
      path = Pathname.new path
      path = dir_path_modular + path
      path.dirname.mkpath
      puts "Writing a new modular task: #{path}"
      File.open(path.to_s, 'w') do |file|
        file.puts content
      end
    end
  end

  def self.main
    purge_tasks
    create_new_wrapped_tasks
    create_new_modular_tasks
  end
end

Tasks.main
