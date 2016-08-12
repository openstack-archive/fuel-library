require 'spec_helper'

describe Puppet::Type.type(:merge_yaml_settings) do
  before(:each) do
    puppet_debug_override
  end

  subject do
    Puppet::Type.type(:merge_yaml_settings)
  end

  it 'should create instance' do
    is_expected.not_to be_nil
  end

  it 'should require path' do
    expect do
      subject.new(
          {
              :title => 'test',
          }
      )
    end.to raise_error Puppet::Error
  end

  it 'should require path as an absolute path' do
    expect do
      subject.new(
          {
              :title => 'test',
              :path => 'test.yaml',
          }
      )
    end.to raise_error Puppet::Error
  end

  it 'should not accept non-structure values for the original data' do
    expect do
      subject.new(
          {
              :title => 'test',
              :path => '/tmp/test.yaml',
              :original_data => :test,
          }
      )
    end.to raise_error Puppet::Error
  end

  it 'should not accept non-absolute file paths for the original data' do
    expect do
      subject.new(
          {
              :title => 'test',
              :path => '/tmp/test.yaml',
              :original_data => 'original.yaml',
          }
      )
    end.to raise_error Puppet::Error
  end

  it 'should not accept non-structure values for the override data' do
    expect do
      subject.new(
          {
              :title => 'test',
              :path => '/tmp/test.yaml',
              :override_data => :test,
          }
      )
    end.to raise_error Puppet::Error
  end

  it 'should not accept non-absolute file paths for the override data' do
    expect do
      subject.new(
          {
              :title => 'test',
              :path => '/tmp/test.yaml',
              :original_data => 'override.yaml',
          }
      )
    end.to raise_error Puppet::Error
  end

  %w(knockout_prefix overwrite_arrays unpack_arrays merge_hash_arrays
  extend_existing_arrays preserve_unmergeables merge_debug sort_merged_arrays).each do |parameter|
    it "should have '#{parameter}' parameter" do
      expect(subject.validparameter? parameter.to_sym).to eq true
    end
  end
end
