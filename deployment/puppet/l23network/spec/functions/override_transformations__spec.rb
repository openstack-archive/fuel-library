require 'spec_helper'
require 'yaml'

describe 'override_transformations' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  before :each do
    #setup_scope
    puppet_debug_override
  end

  it 'should exist' do
    Puppet::Parser::Functions.function('override_transformations').should == 'function_override_transformations'
  end

  it 'should has ability to override existing fields and add new' do
    expect(scope.function_override_transformations([{
      :transformations => [
        { :action   => 'add-br',
          :name     => 'br0' } ,
        { :action   => 'add-br',
          :name     => 'br1',
          :provider => 'ovs' } ,
        { :action   => 'override',
          :name     => 'br0',
          :provider => 'xxx' },
        { :action   => 'override',
          :name     => 'br1',
          :provider => 'lnx' }
      ]
    }])).to eq({
      :transformations => [
        { :action   => 'add-br',
          :name     => 'br0',
          :provider => 'xxx' },
        { :action   => 'add-br',
          :name     => 'br1',
          :provider => 'lnx' },
      ]
    })
  end

  it 'should has ability to remove existing fields' do
    expect(scope.function_override_transformations([{
      :transformations => [
        { :action   => 'add-br',
          :name     => 'br0' } ,
        { :action   => 'add-br',
          :name     => 'br1',
          :provider => 'ovs' } ,
        { :action   => 'override',
          :name     => 'br0',
          :provider => '' },
        { :action   => 'override',
          :name     => 'br1',
          :provider => '' }
      ]
    }])).to eq({
      :transformations => [
        { :action   => 'add-br',
          :name     => 'br0'},
        { :action   => 'add-br',
          :name     => 'br1' }
      ]
    })
  end

  it 'should has ability to change actions' do
    expect(scope.function_override_transformations([{
      :transformations => [
        { :action   => 'add-br',
          :name     => 'br0' } ,
        { :action   => 'add-br',
          :name     => 'br1' } ,
        { :action   => 'override',
          :name     => 'br1',
          :'new-action' => 'noop' }
      ]
    }])).to eq({
      :transformations => [
        { :action   => 'add-br',
          :name     => 'br0'},
        { :action   => 'noop',
          :name     => 'br1' }
      ]
    })
  end

end
# vim: set ts=2 sw=2 et :