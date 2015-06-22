require 'spec_helper'
# this hack is required for now to ensure that the path is set up correctly
# to retrive the parent provider
$LOAD_PATH.push(
  File.join(
    File.dirname(__FILE__),
    '..',
    '..',
    'fixtures',
    'modules',
    'inifile',
    'lib')
)
require 'puppet/type/keystone_paste_ini'
describe 'Puppet::Type.type(:keystone_paste_ini)' do
  before :each do
    @keystone_paste_ini = Puppet::Type.type(:keystone_paste_ini).new(:name => 'DEFAULT/foo', :value => 'bar')
  end
  it 'should accept a valid value' do
    @keystone_paste_ini[:value] = 'bar'
    @keystone_paste_ini[:value].should == 'bar'
  end
end
