require 'spec_helper'
describe 'nova::compute::serial' do

  it { is_expected.to contain_nova_config('serial_console/enabled').with_value('true') }
  it { is_expected.to contain_nova_config('serial_console/port_range').with_value('10000:20000')}
  it { is_expected.to contain_nova_config('serial_console/base_url').with_value('ws://127.0.0.1:6083/')}
  it { is_expected.to contain_nova_config('serial_console/listen').with_value('127.0.0.1')}
  it { is_expected.to contain_nova_config('serial_console/proxyclient_address').with_value('127.0.0.1')}

  context 'when overriding params' do
    let :params do
      {
          :proxyclient_address => '10.10.10.10',
          :listen              => '10.10.11.11',
      }
    end
    it { is_expected.to contain_nova_config('serial_console/proxyclient_address').with_value('10.10.10.10')}
    it { is_expected.to contain_nova_config('serial_console/listen').with_value('10.10.11.11')}
  end

end
