require 'spec_helper'

describe 'cinder::volume::solidfire' do
  let :req_params do
    {
      :san_ip       => '127.0.0.2',
      :san_login    => 'solidfire',
      :san_password => 'password',
    }
  end

  let :params do
    req_params
  end

  describe 'solidfire volume driver' do
    it 'configure solidfire volume driver' do
      should contain_cinder_config('DEFAULT/volume_driver').with_value(
        'cinder.volume.drivers.solidfire.SolidFire')
      should contain_cinder_config('DEFAULT/san_ip').with_value(
        '127.0.0.2')
      should contain_cinder_config('DEFAULT/san_login').with_value(
        'solidfire')
      should contain_cinder_config('DEFAULT/san_password').with_value(
        'password')
    end
  end
end
