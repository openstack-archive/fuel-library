require 'puppet'
describe Puppet::Type.type(:ring_account_device) do

  it 'should fail if the name has no ":"' do
    expect {
      Puppet::Type.type(:ring_account_device).new(:name => 'foo/bar')
    }.to raise_error(Puppet::Error, /should contain address:port\/device/)
  end

  it 'should fail if the name does not contain a "/"' do
    expect {
      Puppet::Type.type(:ring_account_device).new(:name => 'foo:80')
    }.to raise_error(Puppet::Error, /should contain a device/)
  end
end
