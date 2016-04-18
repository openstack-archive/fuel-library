require 'puppet'
require 'net/http'

describe Puppet::Type.type(:haproxy_backend_status).provider(:http) do

  let (:resource) do
    Puppet::Type::Haproxy_backend_status.new(
      {
          :name     => 'test',
          :url      => 'http://10.10.10.5:5000/',
          :provider => 'http'
      }
    )
  end

  let (:http_100) do
    Net::HTTPContinue.new('1.1', '100', 'Continue')
  end

  let (:http_200) do
    Net::HTTPOK.new('1.1', '200', 'OK')
  end

  let (:http_404) do
    Net::HTTPNotFound.new('1.1', '404', 'Not Found')
  end

  let (:http_302) do
    Net::HTTPFound.new('1.1', '302', 'Found')
  end

  let (:http_503) do
    Net::HTTPServiceUnavailable.new('1.1', '503', 'Service Unavailable')
  end

  let (:provider) do
    provider = resource.provider
    if ENV['SPEC_PUPPET_DEBUG']
      class << provider
        def debug(msg)
          puts msg
        end
      end
    end
    provider
  end

  it 'should return :up for running backend (HTTP 200)' do
    resource[:name] = 'test-up'
    provider.stubs(:get_url).returns(http_200)
    expect(provider.ensure).to eq(:up)
  end

  it 'should return :up for running backend (HTTP 302)' do
    resource[:name] = 'test-up'
    provider.stubs(:get_url).returns(http_302)
    expect(provider.ensure).to eq(:up)
  end

  it 'should return :down for broken backend (HTTP 404)' do
    resource[:name] = 'test-down'
    provider.stubs(:get_url).returns(http_404)
    expect(provider.ensure).to eq(:down)
  end

  it 'should return :down for broken backend (HTTP 503)' do
    resource[:name] = 'test-down'
    provider.stubs(:get_url).returns(http_503)
    expect(provider.ensure).to eq(:down)
  end

  it 'should return :present for weird backend (HTTP 100)' do
    resource[:name] = 'test-up'
    provider.stubs(:get_url).returns(http_100)
    expect(provider.ensure).to eq(:present)
  end

  it 'should return :absent for missing backend (conection refused)' do
    resource[:name] = 'test-absent'
    provider.stubs(:get_url).returns(false)
    expect(provider.ensure).to eq(:absent)
  end

end
