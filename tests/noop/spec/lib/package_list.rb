module Noop::Package_list
  def package_resources_lists_dir
    File.expand_path File.join ENV['SPEC_SAVE_PACKAGE_RESOURCES'], self.astute_yaml_base
  end

  def package_resources_list_file(manifest, os)
    file_name = manifest.gsub('/', '_').gsub('.pp', '') + "_#{os}_packages.yaml"
    File.join package_resources_lists_dir, file_name
  end

  def save_package_resources_list(data, os)
    begin
      file_path = package_resources_list_file manifest, os
      FileUtils.mkdir_p package_resources_lists_dir unless File.directory? package_resources_lists_dir
      File.open(file_path, 'w') do |list_file|
        YAML.dump(data, list_file)
      end
    rescue
      puts "Could not save Package resources list for manifest '#{manifest}' to '#{file_path}'"
    else
      puts "Package resources list for manifest '#{manifest}' saved to '#{file_path}'"
    end
  end
end

# it 'should save the list of file resources' do
#   catalog = subject
#   catalog = subject.call if subject.is_a? Proc
#   package_resources = {}
#   catalog.resources.each do |resource|
#     next unless resource.type == 'Package'
#     next if %w(absent purged).include? resource[:ensure] or not resource[:ensure]
#     package_resources[resource[:name]] = resource[:ensure]
#   end
#   if package_resources.any?
#     Noop.save_package_resources_list package_resources, os_name
#   end
# end
