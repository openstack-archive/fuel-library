require 'spec_helper'
require 'fakefs/spec_helpers'

provider_class = Puppet::Type.type(:merge_yaml_settings).provider(:ruby)
describe provider_class do
  include FakeFS::SpecHelpers

  before :each do
    @base_dir = Etc.getpwuid(0).dir
    @sample_filepath = "#{@base_dir}/sample_file_path.yaml"
    @dest_filepath = "#{@base_dir}/dest_file_path.yaml"

    FileUtils.mkdir_p(@base_dir)
  end

  it 'should merge settings if both are present' do

    sample_yaml_text = <<-EOF
      SETTING_A: value1
      SETTING_B: value2
    EOF

    result_yaml_text = <<-EOF
      SETTING_A: new_value1
      SETTING_B: new_value2
      SETTING_C: new_value
    EOF

    settings = {
                 'SETTING_A' => 'new_value1',
                 'SETTING_B' => 'new_value2',
                 'SETTING_C' => 'new_value'
    }

    File.open(@sample_filepath, 'w') { |file| file.write(sample_yaml_text) }

    resource = Puppet::Type::Merge_yaml_settings.new(
      { 
        :name => @dest_filepath,
        :sample_settings => @sample_filepath,
        :provider => 'ruby',
        :override_settings => settings
      }
    )

    provider = provider_class.new(resource)
    provider.create()
    result_content = File.read(@dest_filepath)
    expect(result_content).to eq result_yaml_text
  end
end
