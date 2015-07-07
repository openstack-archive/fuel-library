
require 'puppet'
describe Puppet::Type.type(:ring_container_device) do
  it 'should fail if the name does not contain valid ipaddress' do
    expect {
      Puppet::Type.type(:ring_container_device).new(:name => '192.168.1.256:80/a')
    }.to raise_error(Puppet::ResourceError, /invalid address/)
  end

  it 'should fail if the name does not contain a "/"' do
    expect {
      Puppet::Type.type(:ring_container_device).new(:name => 'foo:80')
    }.to raise_error(Puppet::Error, /should contain a device/)
  end
end
