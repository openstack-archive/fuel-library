require 'spec_helper'
require 'shared-examples'

manifest = 'globals/globals.pp'

describe manifest do

  shared_examples 'catalog' do
    it { should contain_file '/etc/hiera/globals.yaml' }
    it 'should save the globals yaml file' do
      facts[:physicalprocessorcount] = 7
      globals_yaml_content = Noop.resource_parameter_value subject, 'file', '/etc/hiera/globals.yaml', 'content'
      globals_yaml_path = Noop.globals_yaml_path
      raise 'Could not get globals file content!' unless globals_yaml_content
      File.open(globals_yaml_path, 'w') { |file| file.write globals_yaml_content }
      puts "Globals yaml saved to: '#{globals_yaml_path}'" if ENV['SPEC_PUPPET_DEBUG']
    end
  end

  test_ubuntu_and_centos manifest
end



