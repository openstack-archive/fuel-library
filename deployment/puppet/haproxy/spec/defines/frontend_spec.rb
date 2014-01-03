require 'spec_helper'

describe 'haproxy::frontend' do
  let(:title) { 'tyler' }
  let(:facts) {{ :ipaddress => '1.1.1.1' }}

  context "when only one port is provided" do
    let(:params) do
      {
        :name  => 'croy',
        :ports => '18140'
      }
    end

    it { should contain_haproxy__service('croy_frontend').with_content(
      "\nfrontend croy\n  bind 1.1.1.1:18140\n  option  tcplog\n"
    ) }
  end

  context "when an array of ports is provided" do
    let(:params) do
      {
        :name      => 'apache',
        :ipaddress => '23.23.23.23',
        :ports     => [
          '80',
          '443'
        ]
      }
    end

    it { should contain_haproxy__service('apache_frontend').with_content(
      "\nfrontend apache\n  bind 23.23.23.23:80\n  bind 23.23.23.23:443\n  option  tcplog\n"
    ) }
  end

  context "when a comma-separated list of ports is provided" do
    let(:params) do
      {
        :name      => 'apache',
        :ipaddress => '23.23.23.23',
        :ports     => '80,443'
      }
    end

    it { should contain_haproxy_service('apache_frontend').with_content(
      "\nfrontend apache\n  bind 23.23.23.23:80\n  bind 23.23.23.23:443\n  option  tcplog\n"
    ) }
  end
end
