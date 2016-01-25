require 'spec_helper'
require 'yaml'

provider_class = Puppet::Type.type(:merge_yaml_settings).provider(:ruby)
describe provider_class do

  let(:sample_filepath) { "/test/sample_file_path.yaml" }
  let(:settings_filepath) { "/test/settings_file_path.yaml" }
  let(:dest_filepath) { "/test/dest_file_path.yaml" }

  let(:sample) {
    {
      :SETTING_A  => 'Value1',
      :SETTING_B  => 'Value2',
    }
  }

  let(:settings) {
    {
      :SETTING_A => 'new_value1',
      :SETTING_B => 'new_value2',
      :SETTING_C => 'new_value',
    }
  }

  let(:result) {
    {
      :SETTING_A => 'new_value1',
      :SETTING_B => 'new_value2',
      :SETTING_C => 'new_value'
    }
  }

  before(:each) do
    puppet_debug_override()
  end

  it 'should merge settings if sample is file and settings is hash' do

    resource = Puppet::Type::Merge_yaml_settings.new(
      {
        :name              => dest_filepath,
        :sample_settings   => sample_filepath,
        :provider          => 'ruby',
        :override_settings => settings
      }
    )

    provider = provider_class.new(resource)
    provider.stubs(:get_dict).with(sample_filepath).returns(sample)
    provider.stubs(:get_dict).with(settings).returns(settings)
    provider.stubs(:write_to_file).with(dest_filepath, YAML.dump(result)).once
    provider.create()
  end

  it 'should FAIL if file can not be written' do

    resource = Puppet::Type::Merge_yaml_settings.new(
      {
        :name              => dest_filepath,
        :sample_settings   => sample_filepath,
        :provider          => 'ruby',
        :override_settings => settings
      }
    )

    provider = provider_class.new(resource)
    provider.stubs(:get_dict).with(sample_filepath).returns(sample)
    provider.stubs(:get_dict).with(settings).returns(settings)
    File.class.stubs(:open)
              .with(dest_filepath)
              .raises(IOError)
    expect{ provider.create() }.to raise_error(Puppet::Error, %r{merge_yaml_settings:\s+the\s+file\s+\/test\/dest_file_path.yaml\s+can\s+not\s+be\s+written!})
  end


  it 'should merge settings if both are files' do


    resource = Puppet::Type::Merge_yaml_settings.new(
      {
        :name              => dest_filepath,
        :sample_settings   => sample_filepath,
        :provider          => 'ruby',
        :override_settings => settings_filepath
      }
    )

    provider = provider_class.new(resource)
    provider.stubs(:get_dict).with(sample_filepath).returns(sample)
    provider.stubs(:get_dict).with(settings_filepath).returns(settings)
    provider.stubs(:write_to_file).with(dest_filepath, YAML.dump(result)).once
    provider.create()
  end

  it 'should merge settings if both are hashes' do

    resource = Puppet::Type::Merge_yaml_settings.new(
      {
        :name              => dest_filepath,
        :sample_settings   => sample,
        :provider          => 'ruby',
        :override_settings => settings
      }
    )

    provider = provider_class.new(resource)
    provider.stubs(:write_to_file).with(dest_filepath, YAML.dump(result)).once
    provider.create()
  end

  it 'should use sample settings if other is not present' do

    resource = Puppet::Type::Merge_yaml_settings.new(
      {
        :name            => dest_filepath,
        :sample_settings => sample,
        :provider        => 'ruby',
      }
    )

    provider = provider_class.new(resource)
    provider.stubs(:write_to_file).with(dest_filepath, YAML.dump(sample)).once
    provider.create()
  end

  it 'should use new settings if other is not present' do

    resource = Puppet::Type::Merge_yaml_settings.new(
      {
        :name              => dest_filepath,
        :override_settings => settings,
        :provider          => 'ruby',
      }
    )

    provider = provider_class.new(resource)
    provider.stubs(:write_to_file).with(dest_filepath, YAML.dump(settings)).once
    provider.create()
  end

  it 'should not write to file if result is empty' do

    resource = Puppet::Type::Merge_yaml_settings.new(
      {
        :name              => dest_filepath,
        :provider          => 'ruby',
      }
    )

    provider = provider_class.new(resource)
    provider.stubs(:write_to_file).with(dest_filepath, YAML.dump(sample)).never
    provider.create()
  end
end
