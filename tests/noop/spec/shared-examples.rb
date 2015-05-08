shared_examples 'compile' do
  it do
    should compile
  end
end

shared_examples 'should_not_install_bin_files_with_puppet' do
  it 'should not install binary files with puppet' do
    binary_files_regexp = %r{^/bin|^/usr/bin|^/usr/local/bin|^/usr/sbin|^/sbin|^/usr/lib|^/usr/share|^/etc/init.d|^/usr/local/sbin|^/etc/rc\S\.d}
    binary_files = []
    downloaded_files = []
    file_resources.each do |resource|
      next unless %w(present file directory).include? resource[:ensure] or not resource[:ensure]
      file_path = resource[:path] or resource[:title]
      file_source = resource[:source]
      binary_files << file_path if file_path =~ binary_files_regexp
      downloaded_files << file_path if file_source
    end
    error_message_template = <<-eos
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
    fail ERB.new(error_message_template, nil, '-').result(binding) if binary_files.any? or downloaded_files.any?
  end
end

shared_examples 'save_files_list' do
  it 'should save the list of file resources' do
    files={}
    file_resources.each do |resource|
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
      if files.any?
        Noop.save_file_resources_list files, os_name
      end
    end
  end
end

shared_examples 'save_packages_list' do
  it 'should save the list of file resources' do
    catalog = subject
    catalog = subject.call if subject.is_a? Proc
    package_resources = {}
    catalog.resources.each do |resource|
      next unless resource.type == 'Package'
      next if %w(absent purged).include? resource[:ensure] or not resource[:ensure]
      package_resources[resource[:name]] = resource[:ensure]
    end
    if package_resources.any?
      Noop.save_package_resources_list package_resources, os_name
    end
  end
end

shared_examples 'debug' do
  it 'shows catalog contents' do
    Noop.show_catalog subject
  end
end

shared_examples 'generate' do
  it 'shows catalog contents' do
    Noop.catalog_to_spec subject
  end
end

shared_examples 'status' do
  it 'shows status' do
    puts <<-eos
      =============================================
      OS:       #{os_name}
      YAML:     #{Noop.astute_yaml_base}
      Spec:     #{Noop.current_spec example}
      Manifest: #{Noop.manifest}
      Node:     #{Noop.fqdn}
      Role:     #{Noop.hiera 'role'}
      =============================================
    eos
  end
end

shared_examples 'OS' do
  it_behaves_like 'compile'

  it_behaves_like 'status' if ENV['SPEC_SHOW_STATUS']
  it_behaves_like 'debug' if ENV['SPEC_CATALOG_DEBUG']
  it_behaves_like 'generate' if ENV['SPEC_SPEC_GENERATE']
  it_behaves_like 'save_files_list' if ENV['SPEC_SAVE_FILE_RESOURCES']
  it_behaves_like 'save_packages_list'if ENV['SPEC_SAVE_PACKAGE_RESOURCES']
  it_behaves_like 'should_not_install_bin_files_with_puppet' if ENV['SPEC_PUPPET_BINARY_FILES']

  begin
    it_behaves_like 'catalog'
  rescue ArgumentError
    true
  end

  at_exit { RSpec::Puppet::Coverage.report! } if ENV['SPEC_COVERAGE']
end

###############################################################################

def test_ubuntu_and_centos(manifest_file, force_manifest = false)
  # check if task is present in the task list
  unless force_manifest or Noop.manifest_present? manifest_file
    Noop.debug "Manifest '#{manifest_file}' is not enabled on the node '#{Noop.hostname}'. Skipping tests."
    return
  end

  # set manifest file
  before(:all) do
    Noop.manifest = manifest_file
  end

  let(:os_name) do
    os = facts[:operatingsystem]
    os = os.downcase if os
    os
  end

  let(:catalog) do
    catalog = subject
    catalog = subject.call if subject.is_a? Proc
    catalog
  end

  let(:file_resources) do
   files = catalog.resources.select do |resource|
      resource.type == 'File'
   end
   files
  end

  if Noop.test_ubuntu?
    context 'on Ubuntu platforms' do
      let(:facts) { Noop.ubuntu_facts }
      it_behaves_like 'OS'
    end
  end

  if Noop.test_centos?
    context 'on CentOS platforms' do
      let(:facts) { Noop.centos_facts }
      it_behaves_like 'OS'
    end
  end

end

