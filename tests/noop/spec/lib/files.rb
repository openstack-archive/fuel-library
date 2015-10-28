class Noop
  module Files

    # TODO: finish this

    # def file_resources_lists_dir
    #   File.expand_path File.join ENV['SPEC_SAVE_FILE_RESOURCES'], self.astute_yaml_base
    # end
    #
    # def file_resources_list_file(manifest, os)
    #   file_name = manifest.gsub('/', '_').gsub('.pp', '') + "_#{os}_files.yaml"
    #   File.join file_resources_lists_dir, file_name
    # end
    #
    # def save_file_resources_list(data, os)
    #   begin
    #     file_path = file_resources_list_file manifest, os
    #     FileUtils.mkdir_p file_resources_lists_dir unless File.directory? file_resources_lists_dir
    #     File.open(file_path, 'w') do |list_file|
    #       YAML.dump(data, list_file)
    #     end
    #   rescue
    #     puts "Could not save File resources list for manifest: '#{manifest}' to: '#{file_path}'"
    #   else
    #     puts "File resources list for manifest: '#{manifest}' saved to: '#{file_path}'"
    #   end
    # end
    #
    # def check_for_file_installation
    #
    # end
    # it 'should not install binary files with puppet' do
    #     binary_files_regexp = %r{^/bin|^/usr/bin|^/usr/local/bin|^/usr/sbin|^/sbin|^/usr/lib|^/usr/share|^/etc/init.d|^/usr/local/sbin|^/etc/rc\S\.d}
    #     binary_files = []
    #     downloaded_files = []
    #     file_resources.each do |resource|
    #       next unless %w(present file directory).include? resource[:ensure] or not resource[:ensure]
    #       file_path = resource[:path] or resource[:title]
    #       file_source = resource[:source]
    #       binary_files << file_path if file_path =~ binary_files_regexp
    #       downloaded_files << file_path if file_source
    #     end
    #     error_message_template = <<-eos
    # <% if binary_files.any? -%>
    # You have <%= binary_files.length -%> binary files installed with puppet:
    # <% binary_files.each do |file| -%>
    # <%= file %>
    # <% end -%>
    # <% end -%>
    # <% if downloaded_files.any? -%>
    # You are downloading <%= downloaded_files.length -%> binary files installed with puppet:
    # <% downloaded_files.each do |file| -%>
    # <%= file %>
    # <% end -%>
    # <% end -%>
    #     eos
    #     fail ERB.new(error_message_template, nil, '-').result(binding) if binary_files.any? or downloaded_files.any?
    #   end

    # it 'should save the list of file resources' do
    #   files={}
    #   file_resources.each do |resource|
    #     next unless %w(present file directory).include? resource[:ensure] or not resource[:ensure]
    #     if resource[:source]
    #       content = resource[:source]
    #     elsif resource[:content]
    #       content = 'TEMPLATE'
    #     else
    #       content = nil
    #     end
    #     next unless content
    #     files[resource[:path]] = content
    #     if files.any?
    #       Noop.save_file_resources_list files, os_name
    #     end
    #   end
    # end
  end
  extend Files
end
