require 'spec_helper'

describe 'nailgun::nginx_nailgun' do
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
