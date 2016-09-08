require 'spec_helper'

describe 'remove_empty_members' do

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should has ability to remove empty keys from config hashes' do
    is_expected.to run.with_params(
        {
            :endpoints => {
                :'br-fw-admin' =>
                    {
                        'IP' => ['10.88.0.7/24'],
                        'gateway' => '',
                        'vendor_specific' => {'provider_gateway' => '10.88.0.2'}
                    },
                'br-mesh' => ''
            },
            :interfaces => {
                'enp0s3' => {'vendor_specific' => {'bus_info' => '0000:00:03.0', 'driver' => 'e1000'}},
                'enp0s4' => ''
            },
            :provider => 'lnx',
        }
    ).and_return(
        {
            :endpoints => {
                :'br-fw-admin' =>
                    {
                        'IP' => ['10.88.0.7/24'],
                        'gateway' => '',
                        'vendor_specific' => {'provider_gateway' => '10.88.0.2'}
                    },
            },
            :interfaces => {
                'enp0s3' => {'vendor_specific' => {'bus_info' => '0000:00:03.0', 'driver' => 'e1000'}},
            },
            :provider => 'lnx',
        }
    )
  end

end
