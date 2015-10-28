class Noop
  module Files

    def file_resources_lists_dir
      File.expand_path File.join ENV['SPEC_SAVE_FILE_RESOURCES'], astute_yaml_base
    end

    def file_resources_list_file(context)
      file_name = manifest.gsub('/', '_').gsub('.pp', '') + "_#{current_os context}_files.yaml"
      File.join file_resources_lists_dir, file_name
    end

    def catalog_file_resources(context)
      catalog = context.subject
      catalog = catalog.call if catalog.is_a? Proc
      catalog.resources.select do |resource|
        resource.type == 'File'
      end
    end

    def catalog_file_resources_report(context)
      files = {}
      catalog_file_resources(context).each do |resource|
        next unless %w(present file directory).include? resource[:ensure] or not resource[:ensure]
        if resource[:source]
          content = resource[:source]
        elsif resource[:content]
          content = 'TEMPLATE'
        else
          content = nil
        end
        next unless content
        files[resource[:path]] = content
      end
      files
    end

    def save_file_resources_list_to_file(context)
      FileUtils.mkdir_p file_resources_lists_dir unless File.directory? file_resources_lists_dir
      file_path = file_resources_list_file context
      data = catalog_file_resources_report context
      File.open(file_path, 'w') do |list_file|
        YAML.dump(data, list_file)
      end
    end

    def binary_files_report_template(binding)
      template = <<-'eos'
      <% if binary_files.any? -%>
      You have <%= binary_files.length -%> binary files installed with puppet:
      <% binary_files.each do |file| -%>
      <%= file %>
      <% end -%>
      <% end -%>
      <% if downloaded_files.any? -%>
      You are downloading <%= downloaded_files.length -%> binary files installed with puppet:
      <% downloaded_files.each do |file| -%>
      <%= file %>
      <% end -%>
      <% end -%>
      eos
      ERB.new(template, nil, '-').result(binding)
    end

    def check_for_binary_files_installation(context)
      binary_files_regexp = %r{^/bin|^/usr/bin|^/usr/local/bin|^/usr/sbin|^/sbin|^/usr/lib|^/usr/share|^/etc/init.d|^/usr/local/sbin|^/etc/rc\S\.d}
      binary_files = []
      downloaded_files = []
      catalog_file_resources(context).each do |resource|
        next unless %w(present file directory).include? resource[:ensure] or not resource[:ensure]
        file_path = resource[:path] or resource[:title]
        file_source = resource[:source]
        binary_files << file_path if file_path =~ binary_files_regexp
        downloaded_files << file_path if file_source
      end
      report = binary_files_report_template binding
      fail report if binary_files.any? or downloaded_files.any?
    end

  end
  extend Files
end
