require 'spec_helper'

describe 'cinder::backend::solidfire' do
  let (:title) { 'solidfire' }

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
      is_expected.to contain_cinder_config('solidfire/volume_driver').with_value(
        'cinder.volume.drivers.solidfire.SolidFireDriver')
      is_expected.to contain_cinder_config('solidfire/san_ip').with_value(
        '127.0.0.2')
      is_expected.to contain_cinder_config('solidfire/san_login').with_value(
        'solidfire')
      is_expected.to contain_cinder_config('solidfire/san_password').with_value(
        'password')
    end
  end

  describe 'solidfire backend with additional configuration' do
    before :each do
      params.merge!({:extra_options => {'solidfire/param1' => {'value' => 'value1'}}})
    end

    it 'configure solidfire backend with additional configuration' do
      should contain_cinder_config('solidfire/param1').with({
        :value => 'value1',
      })
    end
  end

end
