require 'spec_helper'

describe 'haproxy::backend' do
  let(:title) { 'tyler' }
  let(:facts) {{ :ipaddress => '1.1.1.1' }}

  context "when no options are passed" do
    let (:params) do
      {
        :name => 'bar'
      }
    end

    it { should contain_haproxy__service('bar_backend').with_content(
      "backend bar\n  balance  roundrobin\n  option  tcplog\n  option  ssl-hello-chk\n"
    ) }
  end
end
