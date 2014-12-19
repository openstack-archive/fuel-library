require 'spec_helper'
manifest = 'globals.pp'

describe manifest do
  let :facts do
    Noop.facts
  end

  before :all do
    Noop.set_manifest manifest
  end

  it { should compile }

  it { should contain_file '/etc/hiera/globals.yaml' }

  it 'should save the globals yaml file' do
    catalog = subject
    catalog = subject.call if subject.is_a? Proc
    globals_file_resource = catalog.resource 'file', '/etc/hiera/globals.yaml'
    globals_yaml_path = Noop.globals_yaml_path
    raise 'No globals file resouerce!' unless globals_file_resource
    File.open(globals_yaml_path, 'w') { |file| file.write globals_file_resource[:content] }
    puts "Globals yaml saved to: '#{globals_yaml_path}'"
  end
end
