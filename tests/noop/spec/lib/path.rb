module Noop::Path
  def spec_dir
    return @spec_dir if @spec_dir
    @spec_dir = File.expand_path File.absolute_path File.dirname(__FILE__)
  end

  def module_path
    return ENV['SPEC_MODULEPATH'] if ENV['SPEC_MODULEPATH']
    return @module_path if @module_path
    @module_path = File.expand_path(File.join(spec_dir, '..', '..', '..', '..', 'deployment', 'puppet'))
  end

  def hiera_data_path
    return ENV['SPEC_YAML_DIR'] if ENV['SPEC_YAML_DIR'] and File.directory? ENV['SPEC_YAML_DIR']
    return @hiera_data_path if @hiera_data_path
    @hiera_data_path = File.expand_path(File.join(spec_dir, '..', '..', 'astute.yaml'))
  end

  # def fixtures_path
  #   return @fixtures_path if @fixtures_path
  #   @fixtures_path = File.expand_path(File.join(spec_dir, '..', 'fixtures'))
  # end
  #
  # def hosts_path
  #   return @hosts_path if @hosts_path
  #   @hosts_path = File.expand_path(File.join(spec_dir, 'hosts'))
  # end

  def astute_yaml_name
    return ENV['SPEC_ASTUTE_FILE_NAME'] if ENV['SPEC_ASTUTE_FILE_NAME']
    'novanet-primary-controller.yaml'
  end

  # def puppet_logs_dir
  #   return ENV['SPEC_LOG_DIR'] if ENV['SPEC_PUPPET_LOGS_DIR']
  #   return @puppet_logs_dir if @puppet_logs_dir
  #   @puppet_logs_dir = File.expand_path(File.join(spec_dir, '..', '..', 'logs'))
  # end

  # def puppet_log_file
  #   name = manifest.gsub(/\s+|\//, '_').gsub(/\(|\)/, '') + '.log'
  #   File.join puppet_logs_dir, name
  # end

  def astute_yaml_base
    File.basename(self.astute_yaml_name).gsub(/.yaml$/, '')
  end

  def astute_yaml_path
    File.expand_path(File.join(self.hiera_data_path, self.astute_yaml_name))
  end

  def globals_yaml_path
    File.expand_path(File.join(self.hiera_data_path, self.globlas_prefix + self.astute_yaml_name))
  end

  def globlas_prefix
    'globals_yaml_for_'
  end

  def hiera_data_astute
    self.astute_yaml_base
  end

  def hiera_data_globals
    self.globlas_prefix + self.hiera_data_astute
  end

  def modular_manifests_node_dir
    '/etc/puppet/modules/osnailyfacter/modular'
  end

  def modular_manifests_local_dir
    File.join self.module_path, 'osnailyfacter/modular'
  end
end
