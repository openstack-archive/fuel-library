require 'spec_helper'

describe 'url_available' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  let(:valid_urls) do
    [
      "http://archive.ubuntu.com/ubuntu/",
      "http://mirror.fuel-infra.org/mos/ubuntu/",
      "http://apt.postgresql.org/pub/repos/apt/"
    ]
  end

  let(:invalid_urls) do
    [
      "http://invalid-url.ubuntu.com/ubuntu/",
      "http://mirror.fuel-infra.org/invalid-url"
    ]
  end

  before(:each) do
    valid_urls.each { |valid_url| stub_request(:get, valid_url) }
    invalid_urls.each { |invalid_url| stub_request(:get, invalid_url).to_raise(StandardError) }
    Thread.stubs(:abort_on_exception=)
  end

  it 'should exist' do
    expect(Puppet::Parser::Functions.function('url_available')).to eq 'function_url_available'
  end

  context 'with single values' do
    it 'should be able to process a single value' do
      expect(scope.function_url_available([valid_urls[0]])).to be true
    end

    it 'should throw exception on invalid url' do
      expect{ scope.function_url_available([invalid_urls[0]]) }.to raise_error(Puppet::Error)
    end
  end

  context 'with multiple values' do
    it 'should be able to process an array of values' do
      expect(scope.function_url_available([valid_urls])).to be true
    end

    it 'should throw exception on invalid urls' do
      expect{ scope.function_url_available([invalid_urls]) }.to raise_error(Puppet::Error)
    end
  end
end
