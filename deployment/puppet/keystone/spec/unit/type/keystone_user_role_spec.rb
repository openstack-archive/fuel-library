require 'spec_helper'
require 'puppet'
require 'puppet/type/keystone_user_role'

describe Puppet::Type.type(:keystone_user_role) do

  before :each do
    @user_roles = Puppet::Type.type(:keystone_user_role).new(
    :name => 'foo@bar',
    :roles => ['a', 'b']
    )

    @roles = @user_roles.parameter('roles')
  end

  it 'should not be in sync for' do
    expect(@roles.insync?(['a', 'b', 'c'])).to be false
    expect(@roles.insync?('a')).to be false
    expect(@roles.insync?(['a'])).to be false
    expect(@roles.insync?(nil)).to be false
  end

  it 'should be in sync for' do
    expect(@roles.insync?(['a', 'b'])).to be true
    expect(@roles.insync?(['b', 'a'])).to be true
  end

end
