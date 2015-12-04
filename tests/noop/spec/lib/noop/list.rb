require 'find'

class Noop
  module CLI
    # find all modular task files
    # @return [Array<String>]
    def modular_task_files
      files = []
      Find.find local_modular_manifests_path do |file|
        next unless File.file? file
        next unless file.end_with? '.pp'
        file.gsub! local_modular_manifests_path + '/', ''
        files << file
      end
      files
    end

    # find all astute yaml files
    # @return [Array<String>]
    def astute_yaml_files
      files = []
      Dir.entries(astute_yaml_directory_path).each do |file|
        next unless File.file? File.join astute_yaml_directory_path, file
        next unless file.end_with? '.yaml'
        files << file
      end
      files
    end

    def task_yaml_files
      files = []
      Find.find(module_path) do |file|
        next unless File.file? file
        next unless file.end_with? 'tasks.yaml'
        files << file
      end
      files
    end

    # find all noop spec files
    # @return [Array<String>]
    def noop_spec_files
      files = []
      Find.find(spec_hosts_path) do |file|
        next unless File.file? file
        next unless file.end_with? '_spec.rb'
        file.gsub! spec_hosts_path + '/', ''
        files << file
      end
      files
    end
  end
  extend CLI
end
