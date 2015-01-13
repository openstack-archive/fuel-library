require 'puppet'

describe Puppet::Type.type(:haproxy_backend_status) do

  it 'should accept any backend name' do
    type = Puppet::Type.type(:haproxy_backend_status).new(
        {
            :name => 'test',
            :socket => '/var/run/haproxy.sock',
        })
    expect(type[:name]).to eq('test')
  end

  it 'should accept supported backend status ensure' do
    type = Puppet::Type.type(:haproxy_backend_status).new(
        {
            :name => 'test',
            :socket => '/var/run/haproxy.sock',
            :ensure => 'up',
        })
    expect(type[:ensure]).to eq(:up)

    expect {
      Puppet::Type.type(:haproxy_backend_status).new(
          {
              :name => 'test',
              :socket => '/var/run/haproxy.sock',
              :ensure => 'backup',
          })
    }.to raise_error
  end

  it 'should accept unix socket' do
    type = Puppet::Type.type(:haproxy_backend_status).new(
        {
            :name => 'test',
            :socket => '/var/run/haproxy.sock',
        })
    expect(type[:socket]).to eq('/var/run/haproxy.sock')
  end

  it 'should accept url' do
    type = Puppet::Type.type(:haproxy_backend_status).new(
        {
            :name => 'test',
            :url => 'http://127.0.0.1/;csv',
        })
    expect(type[:url]).to eq('http://127.0.0.1/;csv')
  end

  it 'shoud require either url or socket' do
    expect {
      Puppet::Type.type(:haproxy_backend_status).new(
          {
              :name => 'test',
          })
    }.to raise_error
  end

  it 'should not accept both url and socket' do
    expect {
      Puppet::Type.type(:haproxy_backend_status).new(
          {
              :name => 'test',
              :url => 'http://127.0.0.1/;csv',
              :socket => '/var/run/haproxy.sock',
          })
    }.to raise_error
  end

  it 'should accept correct retry count value' do
    type = Puppet::Type.type(:haproxy_backend_status).new(
        {
            :name => 'test',
            :socket => '/var/run/haproxy.sock',
            :count => '200',
        })
    expect(type[:count]).to eq(200)
    expect {
      Puppet::Type.type(:haproxy_backend_status).new(
          {
              :name => 'test',
              :socket => '/var/run/haproxy.sock',
              :count => 'all',
          })
    }.to raise_error
  end

end
