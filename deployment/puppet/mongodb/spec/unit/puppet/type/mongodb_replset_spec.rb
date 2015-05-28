#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#

require 'puppet'
require 'puppet/type/mongodb_replset'
describe Puppet::Type.type(:mongodb_replset) do

  before :each do
    @replset = Puppet::Type.type(:mongodb_replset).new(:name => 'test')
  end

  it 'should accept a replica set name' do
    expect(@replset[:name]).to eq('test')
  end

  it 'should accept a members array' do
    @replset[:members] = ['mongo1:27017', 'mongo2:27017']
    expect(@replset[:members]).to eq(['mongo1:27017', 'mongo2:27017'])
  end

  it 'should accept admin username' do
    @replset[:admin_username] = 'admin'
    expect(@replset[:admin_username]).to eq('admin')
  end

  it 'should accept admin password' do
    @replset[:admin_password] = 'admin'
    expect(@replset[:admin_password]).to eq('admin')
  end

  it 'should accept admin database' do
    @replset[:admin_database] = 'admin'
    expect(@replset[:admin_database]).to eq('admin')
  end

  it 'should check auth enabled' do
    @replset[:auth_enabled] = true
    expect(@replset[:auth_enabled]).to eq (true)

  it 'should require a name' do
    expect {
      Puppet::Type.type(:mongodb_replset).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

end
