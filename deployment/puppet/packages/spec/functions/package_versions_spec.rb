require 'spec_helper'

describe 'package_versions' do

  before(:each) do
    puppet_debug_override
  end

  it { is_expected.not_to be_nil }

  it { is_expected.to run.with_params('').and_raise_error ArgumentError }

  it { is_expected.to run.with_params({}).and_return({}) }

  context 'with empty catalog' do

    it { is_expected.to run.with_params({'test' => '1'}).and_return({}) }

  end

  context 'with a package in the catalog' do

    before(:each) do
      resource1 = Puppet::Resource.new(
          Puppet::Type.type(:package),
          'test1',
          {
              :parameters => {
                  'ensure' => 'present',
              }
          },
      )
      resource2 = Puppet::Resource.new(
          Puppet::Type.type(:package),
          'test2',
          {
              :parameters => {
                  'ensure' => 'present',
                  'name' => 'real_name',
              }
          },
      )
      scope.catalog.add_resource resource1
      scope.catalog.add_resource resource2
    end

    it 'should update the selected package ensure value' do
      is_expected.to run.with_params(
          {
              'test1' => '1',
              'missing' => '2',
          }).and_return(
          {
              'test1' => '1',
          }
      )
      test1 = scope.catalog.resources.find { |r| r.title == 'test1' }
      expect(test1).not_to be_nil
      expect(test1[:ensure]).to eq('1')
    end

    it 'should be able to use "name" instead of "title" if present' do
      is_expected.to run.with_params(
          {
              'real_name' => '1',
          }).and_return(
          {
              'real_name' => '1',
          }
      )

      test2 = scope.catalog.resources.find { |r| r.title == 'test2' }
      expect(test2).not_to be_nil
      expect(test2[:ensure]).to eq('1')
    end

  end

end
