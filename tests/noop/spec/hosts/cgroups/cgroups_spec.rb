require 'spec_helper'
require 'shared-examples'
manifest = 'cgroups/cgroups.pp'

cgroups_hash = Noop.hiera_structure('cgroups', {})
describe manifest do

  before(:each) do
    Noop.puppet_function_load :prepare_cgroups_hash
    MockFunction.new(:prepare_cgroups_hash) do |function|
      allow(function).to receive(:call).with(cgroups_hash).and_return(nil)
    end
  end

  shared_examples 'catalog' do
    if cgroups_hash
      it 'should declare cgroups class correctly' do
        should contain_class('cgroups').with(
          'cgroups_set'  => {},
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end
