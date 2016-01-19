require 'spec_helper'
require 'shared-examples'

manifest = 'globals/globals.pp'

describe manifest do

  shared_examples 'catalog' do
    it { should contain_file '/etc/hiera/globals.yaml' }
    it 'should save the globals yaml file' do
      globals_yaml_content = Noop.resource_parameter_value self, 'file', '/etc/hiera/globals.yaml', 'content'
      globals_yaml_path = Noop.globals_yaml_path
      globals_yaml_folder = Noop.hiera_globals_folder_path
      Dir.mkdir globals_yaml_folder unless File.directory? globals_yaml_folder
      raise 'Could not get globals file content!' unless globals_yaml_content
      File.open(globals_yaml_path, 'w') { |file| file.write globals_yaml_content }
      puts "Globals yaml saved to: '#{globals_yaml_path}'" if ENV['SPEC_PUPPET_DEBUG']
    end

    it 'should configure os_package_type fact' do
      if facts[:osfamily] == 'Debian'
        should contain_file('/etc/facter/facts.d/os_package_type.txt').with(
          :content => 'os_package_type=ubuntu\n'
        )
      else
        should_not contain_file('/etc/facter/facts.d/os_package_type.txt')
      end
    end
  end

  test_ubuntu_and_centos manifest
end



