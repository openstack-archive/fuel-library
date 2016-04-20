require 'spec_helper'

describe Puppet::Type.type(:hiera_config) do

  subject do
    Puppet::Type.type(:hiera_config)
  end

  let(:params) do
    {
      :path => '/etc/hiera.yaml',
      :hierarchy => %w(base additional),
    }
  end

  it 'should be able to create an instance' do
    expect(subject.new params).not_to be_nil
  end

  [:path, :logger, :backends, :data_dir, :hierarchy, :hierarchy_override, :merge_behavior, :metadata_yaml_file, :additions].each do |param|
    it "should have a #{param} parameter" do
      expect(subject.valid_parameter?(param)).to be_truthy
    end
  end

  it 'can munge the additions structure' do
    resource = subject.new params
    resource[:additions] = {
        'test' => 'a',
        'logger' => 'my',
    }
    expected = {
        :test => 'a',
    }
    expect(resource[:additions]).to eq(expected)
  end

  it 'will allow only hash additions values' do
    resource = subject.new params
    expect do
      resource[:additions] = 'test'
    end.to raise_error /should be a Hash/
  end

end


