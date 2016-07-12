require 'spec_helper'

describe 'osnailyfacter::wait_for_nova_backends' do
  let :facts do
    {
      :osfamily               => 'Debian',
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '14.04',
      :concat_basedir         => '/var/lib/puppet/concat'
    }
  end

  context 'all backends' do
    let :params do
      {
        :management_vip   => '127.0.0.1',
        :service_endpoint => '127.0.0.2',
      }
    end

    it 'should wait for correct backends' do
      is_expected.to contain_osnailyfacter__wait_for_backend('nova-api').with(
        :lb_hash => {
          'nova-api'          => {
            'name'     => 'nova-api',
            'step'     => 6,
            'count'    => 200,
            'provider' => 'haproxy',
            'url'      => 'http://127.0.0.2:10000/;csv'
          },
          'nova-metadata-api' => {
            'name'     => 'nova-metadata-api',
            'step'     => 6,
            'count'    => 200,
            'provider' => 'haproxy',
            'url'      => 'http://127.0.0.2:10000/;csv'
          },
          'nova-novncproxy'   => {
            'name'     => 'nova-novncproxy',
            'step'     => 6,
            'count'    => 200,
            'provider' => 'haproxy',
            'url'      => 'http://127.0.0.2:10000/;csv'
          },
        }
      )
    end
  end

  context 'only one backend' do
    let :params do
      {
        :backends         => ['nova-api'],
        :management_vip   => '127.0.0.1',
        :service_endpoint => '127.0.0.2',
      }
    end

    it 'should wait for correct backends' do
      is_expected.to contain_osnailyfacter__wait_for_backend('nova-api').with(
        :lb_hash => {
          'nova-api'          => {
            'name'     => 'nova-api',
            'step'     => 6,
            'count'    => 200,
            'provider' => 'haproxy',
            'url'      => 'http://127.0.0.2:10000/;csv'
          }
        }
      )
    end
  end

  context 'only one backend and external lb' do
    let :params do
      {
        :backends         => ['nova-api'],
        :management_vip   => '127.0.0.1',
        :service_endpoint => '127.0.0.2',
        :external_lb      => true
      }
    end

    it 'should wait for correct backends' do
      is_expected.to contain_osnailyfacter__wait_for_backend('nova-api').with(
        :lb_hash => {
          'nova-api'          => {
            'name'     => 'nova-api',
            'step'     => 6,
            'count'    => 200,
            'provider' => 'http',
            'url'      => 'http://127.0.0.2:8774'
          },
        }
      )
    end
  end

end
