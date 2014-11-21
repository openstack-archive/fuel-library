require 'puppet'

describe Puppet::Type.type(:haproxy_backend_online) do

  it 'should accept any backend name and require it' do
    type = Puppet::Type.type(:haproxy_backend_online).new(
        :name => 'test_is_online',
        :backend => 'test',
        :socket => '/var/run/haproxy.sock',
    )
    expect(type[:backend]).to eq('test')

    expect {
      Puppet::Type.type(:haproxy_backend_online).new(
          :name => 'test_is_online',
          :socket => '/var/run/haproxy.sock',
      )
    }.to raise_error
  end

  it 'should accept supported backend statuses' do
    type = Puppet::Type.type(:haproxy_backend_online).new(
        :name => 'test_is_online',
        :backend => 'test',
        :socket => '/var/run/haproxy.sock',
        :status => 'up',
    )
    expect(type[:status]).to eq(:up)

    expect {
      Puppet::Type.type(:haproxy_backend_online).new(
          :name => 'test_is_online',
          :backend => 'test',
          :socket => '/var/run/haproxy.sock',
          :status => 'backup',
      )
    }.to raise_error
  end

  it 'should accept either url or socket but not both' do
    type = Puppet::Type.type(:haproxy_backend_online).new(
        :name => 'test_is_online',
        :backend => 'test',
        :socket => '/var/run/haproxy.sock',
    )
    expect(type[:socket]).to eq('/var/run/haproxy.sock')

    type = Puppet::Type.type(:haproxy_backend_online).new(
        :name => 'test_is_online',
        :backend => 'test',
        :url => 'http://127.0.0.1/;csv',
    )
    expect(type[:url]).to eq('http://127.0.0.1/;csv')

    expect {
      Puppet::Type.type(:haproxy_backend_online).new(
          :name => 'test_is_online',
          :backend => 'test',
      )
    }.to raise_error

    expect {
      Puppet::Type.type(:haproxy_backend_online).new(
          :name => 'test_is_online',
          :backend => 'test',
          :url => 'http://127.0.0.1/;csv',
          :socket => '/var/run/haproxy.sock',
      )
    }.to raise_error
  end

end
