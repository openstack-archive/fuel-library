require 'spec_helper'

describe 'direct_networks' do

  let(:endpoints) do
    {
      'br-ex' => {
        'IP' => 'none',
        'gateway' => '',
        'vendor_specific' => {}
      },
      'br-fw-admin' => {
        'IP' => ['10.109.0.7/24'],
        'vendor_specific' => {'provider_gateway' => '10.109.0.2'}
      },
      'br-mgmt' => {
        'IP' => ['10.109.1.3/24'],
        'gateway' => '10.109.1.1',
        'gateway-metric' => 100,
        'routes' => [
          {
            'net' => '10.109.242.0/24',
            'via' => '10.109.1.1',
          },
        ]
      },
      'br-storage' => {
        'IP' => ['10.109.2.1/24']
      },
      'br-ex-lnx' => {
        'IP' => ['10.109.3.4/24'],
        'gateway' => '10.109.3.1',
        'vendor_specific' => {'provider_gateway' => '10.109.3.1'}
      },
      'br-aux' => {
        'IP' => 'none'
      },
      'br-prv' => '',
      'br-floating' => '',
    }
  end

  it { is_expected.not_to eq(nil) }
  it { is_expected.to run.with_params().and_raise_error(ArgumentError, /Wrong number of arguments given/) }
  it { is_expected.to run.with_params([{'br-ex' => 'routes'}]).and_raise_error(ArgumentError, /Requires hash/) }
  it { is_expected.to run.with_params(endpoints, 'br-ex', 'cidra').and_raise_error(ArgumentError, /Expected a string with one of/) }

  it { is_expected.to run.with_params(endpoints).and_return('10.109.0.0/24 10.109.1.0/24 10.109.242.0/24 10.109.2.0/24 10.109.3.0/24')}
  it { is_expected.to run.with_params(endpoints, 'br-mgmt').and_return('10.109.1.0/24 10.109.242.0/24')}
  it { is_expected.to run.with_params(endpoints, 'br-mgmt', 'netmask').and_return('10.109.1.0/255.255.255.0 10.109.242.0/255.255.255.0')}

end
