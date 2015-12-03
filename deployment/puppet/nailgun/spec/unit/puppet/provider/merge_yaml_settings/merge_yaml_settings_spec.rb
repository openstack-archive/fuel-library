require 'spec_helper'
require 'yaml'

provider_class = Puppet::Type.type(:merge_yaml_settings).provider(:ruby)
describe provider_class do

  before :each do
    @sample_filepath   = "/test/sample_file_path.yaml"
    @settings_filepath = "/test/settings_file_path.yaml"
    @dest_filepath     = "/test/dest_file_path.yaml"

    @sample = {
      'SETTING_A'  => 'Value1',
      'SETTING_B'  => 'Value2'
    }

    @result = {
      'SETTING_A' => 'new_value1',
      'SETTING_B' => 'new_value2',
      'SETTING_C' => 'new_value'
    }

    @settings = {
      'SETTING_A' => 'new_value1',
      'SETTING_B' => 'new_value2',
      'SETTING_C' => 'new_value'
    }
  end

  it 'should merge settings if sample is file and settings is hash' do

    expect(YAML).to receive(:load_file).with(@sample_filepath).and_return(@sample)

    resource = Puppet::Type::Merge_yaml_settings.new(
      {
        :name              => @dest_filepath,
        :sample_settings   => @sample_filepath,
        :provider          => 'ruby',
        :override_settings => @settings
      }
    )

    provider = provider_class.new(resource)
    expect(provider).to receive(:write_to_file).with(@dest_filepath, YAML.dump(@result))
    provider.create()
  end

  it 'should merge settings if both are files' do

    expect(YAML).to receive(:load_file).with(@sample_filepath).and_return(@sample)
    expect(YAML).to receive(:load_file).with(@settings_filepath).and_return(@settings)

    resource = Puppet::Type::Merge_yaml_settings.new(
      {
        :name              => @dest_filepath,
        :sample_settings   => @sample_filepath,
        :provider          => 'ruby',
        :override_settings => @settings_filepath
      }
    )

    provider = provider_class.new(resource)
    expect(provider).to receive(:write_to_file).with(@dest_filepath, YAML.dump(@result))
    provider.create()
  end

  it 'should merge settings if both are hashes' do

    resource = Puppet::Type::Merge_yaml_settings.new(
      {
        :name              => @dest_filepath,
        :sample_settings   => @sample,
        :provider          => 'ruby',
        :override_settings => @settings
      }
    )

    provider = provider_class.new(resource)
    expect(provider).to receive(:write_to_file).with(@dest_filepath, YAML.dump(@result))
    provider.create()
  end

  it 'should use sample settings if other is not present' do

    resource = Puppet::Type::Merge_yaml_settings.new(
      {
        :name            => @dest_filepath,
        :sample_settings => @sample,
        :provider        => 'ruby',
      }
    )

    provider = provider_class.new(resource)
    expect(provider).to receive(:write_to_file).with(@dest_filepath, YAML.dump(@sample))
    provider.create()
  end

  it 'should use new settings if other is not present' do

    resource = Puppet::Type::Merge_yaml_settings.new(
      {
        :name              => @dest_filepath,
        :override_settings => @settings,
        :provider          => 'ruby',
      }
    )

    provider = provider_class.new(resource)
    expect(provider).to receive(:write_to_file).with(@dest_filepath, YAML.dump(@settings))
    provider.create()
  end

  it 'should not write to file if result is empty' do

    resource = Puppet::Type::Merge_yaml_settings.new(
      {
        :name              => @dest_filepath,
        :provider          => 'ruby',
      }
    )

    provider = provider_class.new(resource)
    expect(provider).to receive(:write_to_file).never
    provider.create()
  end
end
