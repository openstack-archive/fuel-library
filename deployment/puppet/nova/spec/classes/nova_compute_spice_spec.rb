require 'spec_helper'
describe 'nova::compute::spice' do

  it { is_expected.to contain_nova_config('spice/enabled').with_value('true')}
  it { is_expected.to contain_nova_config('spice/agent_enabled').with_value('true')}
  it { is_expected.to contain_nova_config('spice/server_proxyclient_address').with_value('127.0.0.1')}
  it { is_expected.to_not contain_nova_config('spice/html5proxy_base_url')}
  it { is_expected.to contain_nova_config('spice/server_listen').with_value(nil)}

  context 'when overriding params' do
    let :params do
      {
          :proxy_host    => '10.10.10.10',
          :server_listen => '10.10.11.11',
          :agent_enabled => false
      }
    end
    it { is_expected.to contain_nova_config('spice/html5proxy_base_url').with_value('http://10.10.10.10:6082/spice_auto.html')}
    it { is_expected.to contain_nova_config('spice/server_listen').with_value('10.10.11.11')}
    it { is_expected.to contain_nova_config('spice/agent_enabled').with_value('false')}
  end

end
