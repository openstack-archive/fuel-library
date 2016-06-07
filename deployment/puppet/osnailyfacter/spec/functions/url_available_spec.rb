require 'spec_helper'

describe 'url_available' do

  let(:valid_urls) do
    %w(
    http://archive.ubuntu.com/ubuntu/
    http://mirror.fuel-infra.org/mos/ubuntu/
    http://apt.postgresql.org/pub/repos/apt/
    )
  end

  let(:invalid_urls) do
    %w(
    http://invalid-url.ubuntu.com/ubuntu/
    http://mirror.fuel-infra.org/invalid-url
    )
  end

  before(:each) do
    valid_urls.each { |valid_url| stub_request(:get, valid_url) }
    invalid_urls.each { |invalid_url| stub_request(:get, invalid_url).to_raise(StandardError) }
    Thread.stubs(:abort_on_exception=)
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  context 'with single values' do
    it 'should be able to process a single value' do
      is_expected.to run.with_params(valid_urls[0]).and_return(true)
    end

    it 'should throw exception on invalid url' do
      is_expected.to run.with_params(invalid_urls[0]).and_raise_error(Puppet::Error)
    end
  end

  context 'with multiple values' do
    it 'should be able to process an array of values' do
      is_expected.to run.with_params(valid_urls).and_return(true)
    end

    it 'should throw exception on invalid urls' do
      is_expected.to run.with_params(invalid_urls).and_raise_error(Puppet::Error)
    end
  end
end
