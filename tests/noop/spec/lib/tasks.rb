module Noop::Tasks

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

  def manifest_present?(manifest)
    manifest_path = File.join self.modular_manifests_node_dir, manifest
    tasks.each do |task|
      next unless task['type'] == 'puppet'
      next unless task['parameters']['puppet_manifest'] == manifest_path
      if task['role']
        return true if task['role'] == '*'
        return true if task['role'].include?(role)
      end
      if task['groups']
        return true if task['groups'] == '*'
        return true if task['groups'].include?(role)
      end
    end
    false
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
    context.facts.fetch(:operatingsystem, '').downcase
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
