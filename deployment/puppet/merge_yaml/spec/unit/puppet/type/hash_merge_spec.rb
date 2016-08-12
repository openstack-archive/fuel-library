require 'spec_helper'

describe Puppet::Type.type(:hash_merge) do
  subject do
    Puppet::Type.type(:hash_merge)
  end

  before(:each) do
    puppet_debug_override
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  %w(path hash_name type knockout_prefix overwrite_arrays unpack_arrays merge_hash_arrays extend_existing_arrays).each do |param|
    it "should have a #{param} parameter" do
      expect(subject.validparameter?(param.to_sym)).to be_truthy
    end

    it "should have documentation for its #{param} parameter" do
      expect(subject.paramclass(param.to_sym).doc).to be_a String
    end
  end

  context 'fragment data collection' do
    let(:fragment) do
      Puppet::Type.type(:hash_fragment)
    end

    let(:catalog) do
      Puppet::Resource::Catalog.new
    end

    let(:test1) do
      fragment.new(
          {
              :name => 'test1',
              :hash_name => 'test',
              :priority => 1,
              :data => {
                  'a' => '1',
              }
          }
      )
    end

    let(:test2) do
      fragment.new(
          {
              :name => 'test2',
              :hash_name => 'test',
              :priority => 2,
              :data => {
                  'a' => '2',
              }
          }
      )
    end

    let(:test3) do
      fragment.new(
          {
              :name => 'test3',
              :hash_name => 'test',
              :priority => 3,
              :type => :json,
              :content => '{"c":"3"}',
          }
      )
    end

    let(:test4) do
      fragment.new(
          {
              :name => 'test4',
              :hash_name => 'test',
              :priority => 4,
              :type => :yaml,
              :content => '
---
d:
  - a
  - b
  - c
',
          }
      )
    end

    let(:test5) do
      fragment.new(
          {
              :name => 'test5',
              :hash_name => 'test',
              :priority => 5,
              :type => :json,
              :content => '{"a":"3"}',
          }
      )
    end

    let(:merge) do
      subject.new(
          {
              :name => 'test.yaml',
              :hash_name => 'test',
              :path => '/tmp/test.yaml',
          }
      )
    end

    before(:each) do
      catalog.add_resource merge
      catalog.add_resource test1
      catalog.add_resource test2
      catalog.add_resource test3
      catalog.add_resource test4
      catalog.add_resource test5
      generate
    end

    let(:generate) do
      merge_resource = catalog.resources.find { |r| r.type == :hash_merge }
      merge_resource.generate
      merge_resource
    end

    it 'can collect the data blocks' do
      ral_merge = generate
      expect(ral_merge[:data]).to eq(
                                      {
                                          "a" => "3",
                                          "c" => "3",
                                          "d" => ["a", "b", "c"],
                                      }
                                  )
    end
  end

end


