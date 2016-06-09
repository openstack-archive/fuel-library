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
          :override => 'br0',
          :provider => 'xxx' },
        { :action   => 'override',
          :override => 'br1',
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
          :override => 'br0',
          :provider => '' },
        { :action   => 'override',
          :override => 'br1',
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

  it 'should has ability to change name and actions' do
    expect(scope.function_override_transformations([{
      :transformations => [
        { :action   => 'add-br',
          :name     => 'br0' } ,
        { :action   => 'add-br',
          :name     => 'br1' } ,
        { :action   => 'override',
          :override => 'br0',
          :name     => 'br0-new' },
        { :action   => 'override',
          :override => 'br1',
          :'override-action' => 'noop' }
      ]
    }])).to eq({
      :transformations => [
        { :action   => 'add-br',
          :name     => 'br0-new'},
        { :action   => 'noop',
          :name     => 'br1' }
      ]
    })
  end

  it 'should has ability to override "add-patch" action' do
    expect(scope.function_override_transformations([{
      :transformations => [
        { :action   => 'add-br',
          :name     => 'br0' } ,
        { :action   => 'add-br',
          :name     => 'br1' } ,
        { :action   => 'add-br',
          :name     => 'br2' } ,            # this bridge will be removed by changing action to 'noop'
        { :action   => 'add-patch',
          :bridges  => ['br1','br2'] } ,
        { :action   => 'override',          # override for existing patch
          :override => 'patch-br1:br2',
          :bridges  => ['br0','br1'] },
        { :action   => 'override',          # override for non-existing patch
          :override => 'patch-br4:br5',
          :bridges  => ['br0','br1'] },
        { :action   => 'override',
          :override => 'br2',
          :'override-action' => 'noop' }
      ]
    }])).to eq({
      :transformations => [
        { :action   => 'add-br',
          :name     => 'br0' } ,
        { :action   => 'add-br',
          :name     => 'br1' } ,
        { :action   => 'noop',
          :name     => 'br2' } ,
        { :action   => 'add-patch',
          :bridges  => ['br0','br1'] }
      ]
    })
  end

end
# vim: set ts=2 sw=2 et :