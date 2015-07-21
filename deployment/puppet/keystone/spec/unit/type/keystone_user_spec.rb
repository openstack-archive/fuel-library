require 'spec_helper'
require 'puppet'
require 'puppet/type/keystone_user'

describe Puppet::Type.type(:keystone_user) do

  before :each do
    @project = Puppet::Type.type(:keystone_user).new(
    :name   => 'foo',
    :domain => 'foo-domain',
    )

    @domain = @project.parameter('domain')
  end

  it 'should not be in sync for domain changes' do
    expect { @domain.insync?('not-the-domain') }.to raise_error(Puppet::Error, /The domain cannot be changed from/)
    expect { @domain.insync?(nil) }.to raise_error(Puppet::Error, /The domain cannot be changed from/)
  end

  it 'should be in sync if domain is the same' do
    expect(@domain.insync?('foo-domain')).to be true
  end

end
