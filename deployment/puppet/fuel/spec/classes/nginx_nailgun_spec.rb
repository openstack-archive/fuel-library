require 'spec_helper'

describe 'fuel::nginx::services' do
  context 'when TLS enabled' do
    let :params do
    {
        :staticdir => '/var/www/static/',
        :logdumpdir => '/var/log/',
        :ssl_enabled => true,
    }
    end

    it 'should create new Diffie-Hellmann parameters file' do
      should contain_exec('create new dhparam file')
    end
  end
end
