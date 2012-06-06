
require 'puppet'
describe Puppet::Type.type(:ring_container_device) do

  it 'should fail if the name has no ":"' do
    expect do
      Puppet::Type.type(:ring_account_device).new(:name => 'foo/bar')
    end.should raise_error(Puppet::Error, /should contain address:port\/device/)
  end

  it 'should fail if the name does not contain a "/"' do
    expect do
      Puppet::Type.type(:ring_account_device).new(:name => 'foo:80')
    end.should raise_error(Puppet::Error, /should contain a device/)
  end
end
