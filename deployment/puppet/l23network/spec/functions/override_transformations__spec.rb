require 'spec_helper'
require 'yaml'

describe 'override_transformations' do
  before :each do
    puppet_debug_override
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should has ability to override existing fields and add new' do

    is_expected.to run.with_params(
        {
            :transformations => [
                {:action => 'add-br',
                 :name => 'br0'},
                {:action => 'add-br',
                 :name => 'br1',
                 :provider => 'ovs'},
                {:action => 'override',
                 :override => 'br0',
                 :provider => 'xxx'},
                {:action => 'override',
                 :override => 'br1',
                 :provider => 'lnx'}
            ]
        }
    ).and_return(
        {
            :transformations => [
                {:action => 'add-br',
                 :name => 'br0',
                 :provider => 'xxx'},
                {:action => 'add-br',
                 :name => 'br1',
                 :provider => 'lnx'},
            ]
        }
    )
  end

  it 'should has ability to remove existing fields' do
    is_expected.to run.with_params(
        {
            :transformations => [
                {:action => 'add-br',
                 :name => 'br0'},
                {:action => 'add-br',
                 :name => 'br1',
                 :provider => 'ovs'},
                {:action => 'override',
                 :override => 'br0',
                 :provider => ''},
                {:action => 'override',
                 :override => 'br1',
                 :provider => ''}
            ]
        }
    ).and_return(
        {
            :transformations => [
                {:action => 'add-br',
                 :name => 'br0'},
                {:action => 'add-br',
                 :name => 'br1'}
            ]
        }
    )
  end

  it 'should has ability to change name and actions' do
    is_expected.to run.with_params(
        {
            :transformations => [
                {:action => 'add-br',
                 :name => 'br0'},
                {:action => 'add-br',
                 :name => 'br1'},
                {:action => 'override',
                 :override => 'br0',
                 :name => 'br0-new'},
                {:action => 'override',
                 :override => 'br1',
                 :'override-action' => 'noop'}
            ]
        }
    ).and_return(
        {
            :transformations => [
                {:action => 'add-br',
                 :name => 'br0-new'},
                {:action => 'noop',
                 :name => 'br1'}
            ]
        }
    )
  end

  it 'should has ability to override "add-patch" action' do
    is_expected.to run.with_params(
        {
            :transformations => [
                {:action => 'add-br',
                 :name => 'br0'},
                {:action => 'add-br',
                 :name => 'br1'},
                {:action => 'add-br',
                 :name => 'br2'}, # this bridge will be removed by changing action to 'noop'
                {:action => 'add-patch',
                 :bridges => ['br1', 'br2']},
                {:action => 'override', # override for existing patch
                 :override => 'patch-br1:br2',
                 :bridges => ['br0', 'br1']},
                {:action => 'override', # override for non-existing patch
                 :override => 'patch-br4:br5',
                 :bridges => ['br0', 'br1']},
                {:action => 'override',
                 :override => 'br2',
                 :'override-action' => 'noop'}
            ]
        }
    ).and_return(
        {
            :transformations => [
                {:action => 'add-br',
                 :name => 'br0'},
                {:action => 'add-br',
                 :name => 'br1'},
                {:action => 'noop',
                 :name => 'br2'},
                {:action => 'add-patch',
                 :bridges => ['br0', 'br1']}
            ]
        }
    )
  end

end
