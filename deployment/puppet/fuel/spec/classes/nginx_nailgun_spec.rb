require 'spec_helper'

describe 'fuel::nginx::services' do
  shared_examples_for "fuel nginx services" do
    context 'when TLS enabled' do
      let :params do
        {
          :staticdir => '/var/www/static/',
          :logdumpdir => '/var/log/',
          :ssl_enabled => true,
        }
      end

      it 'should create ssl file' do
        should contain_openssl__certificate__x509('nginx')
      end
    end
  end

  on_supported_os(supported_os: supported_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      it_configures "fuel nginx services"
    end
  end
end
