module Noop::Catalog
  def dump_catalog(subject, resources)
    p resources
    catalog = subject
    catalog = subject.call if subject.is_a? Proc
    text = ''
    catalog.resources.each do |resource|
      text += '# ' + ('=' * 60) + "\n"
      text += resource.to_manifest + "\n"
    end
    text
  end

  def catalogs_dir
    return @catalogs_dir if @catalogs_dir
    @catalogs_dir = File.join spec_dir, 'catalogs'
  end

  def catalog_manifest_base_dir
    File.join catalogs_dir, astute_yaml_base
  end

  def catalog_dump_file_path
    manifest_name = manifest.gsub '/', '-'
    File.join catalog_manifest_base_dir, "#{manifest_name}-#{os}-catalog.pp"
  end

  def save_catalog_to_file(subject, resources)
    require 'pry'
    binding.pry
    FileUtils.mkdir_p catalog_manifest_base_dir unless File.directory? catalog_manifest_base_dir
    debug "Saving catalog to: '#{catalog_dump_file_path}'"
    File.open(catalog_dump_file_path, 'w') do |file|
      file.puts dump_catalog subject, resources
    end
  end

  def read_catalog_from_file
    debug "Read catalog from: '#{catalog_dump_file_path}'"
    File.read catalog_dump_file_path
  end

end
