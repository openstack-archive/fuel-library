require 'puppet'
require 'puppet/type/nova_network'
describe 'Puppet::Type.type(:nova_network)' do
  it 'should reject an invalid ipv4 CIDR value' do
    expect { Puppet::Type.type(:nova_network).new(:network => '192.168.1.0') }.to raise_error(Puppet::Error, /Invalid value/)
    expect { Puppet::Type.type(:nova_network).new(:network => '::1/24') }.to raise_error(Puppet::Error, /Invalid value/)
  end
  it 'should accept a valid ipv4 CIDR value' do
    Puppet::Type.type(:nova_network).new(:network => '192.168.1.0/24')
  end
end
