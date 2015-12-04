class Noop
  module Tasks

    def manifest=(manifest)
      debug "Set manifest to: #{manifest} -> #{File.join self.modular_manifests_local_dir, manifest}"
      RSpec.configuration.manifest = File.join self.modular_manifests_local_dir, manifest
      @manifest = manifest
    end

    def manifest_path
      RSpec.configuration.manifest
    end

    def manifest
      @manifest
    end

    def hiera_test_tasks
      return @hiera_test_tasks if @hiera_test_tasks
      test_tasks = hiera 'test_tasks'
      return unless test_tasks.is_a? Array
      @hiera_test_tasks = test_tasks.map do |manifest|
        manifest.gsub! '_spec.rb', '' if manifest.end_with? '_spec.rb'
        manifest += '.pp' unless manifest.end_with? '.pp'
        manifest
      end
    end

    def test_tasks_present?
      hiera_test_tasks.is_a? Array
    end

    def manifest_present?(manifest)
      return hiera_test_tasks.include? manifest if test_tasks_present?
      manifest_path = File.join self.modular_manifests_node_dir, manifest
      tasks.any? do |task|
        task['type'] == 'puppet' and
            task['parameters']['puppet_manifest'] == manifest_path
      end
    end

    def tasks
      return @tasks if @tasks
      @tasks = []
      Find.find(module_path) do |file|
        next unless File.file? file
        next unless file.end_with? 'tasks.yaml'
        task = YAML.load_file(file)
        @tasks += task if task.is_a? Array
      end
      @tasks
    end

    # this functions returns the name of the currently running spec
    # @return [String]
    def current_spec(context)
      example = context.example
      return unless example
      example_group = lambda do |metdata|
        return example_group.call metdata[:example_group] if metdata[:example_group]
        return example_group.call metdata[:parent_example_group] if metdata[:parent_example_group]
        file_path = metdata[:absolute_file_path]
        return file_path
      end
      example_group.call example.metadata
    end

    def current_os(context)
      context.os
    end

    def test_ubuntu?
      return true unless ENV['SPEC_TEST_UBUNTU'] or ENV['SPEC_TEST_CENTOS']
      true if ENV['SPEC_TEST_UBUNTU']
    end

    def test_centos?
      return true unless ENV['SPEC_TEST_UBUNTU'] or ENV['SPEC_TEST_CENTOS']
      true if ENV['SPEC_TEST_CENTOS']
    end
  end
  extend Tasks
end
