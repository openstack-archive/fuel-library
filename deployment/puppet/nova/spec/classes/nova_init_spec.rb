require 'spec_helper'

describe 'nova' do

  let :facts do
    { :osfamily => 'Debian' }
  end

  describe 'with default parameters' do
    it { should contain_package('python').with_ensure('present') }
    it { should contain_package('python-greenlet').with(
      'ensure'  => 'present',
      'require' => 'Package[python]'
    )}
    it { should contain_package('python-nova').with(
      'ensure'  => 'present',
      'require' => 'Package[python-greenlet]'
    )}
    it { should contain_package('nova-common').with(
      'name'   => 'nova-common',
      'ensure' => 'present'
    )}

    it { should contain_group('nova').with(
        'ensure'  => 'present',
        'system'  => 'true',
        'require' => 'Package[nova-common]'
    )}

    it { should contain_user('nova').with(
        'ensure'  => 'present',
        'gid'     => 'nova',
        'system'  => 'true',
        'require' => 'Package[nova-common]'
    ) }

    it { should contain_file('/var/log/nova').with(
      'ensure'  => 'directory',
      'mode'    => '0751',
      'owner'   => 'nova',
      'group'   => 'nova',
      'require' => 'Package[nova-common]'
    )}

    it { should contain_file('/etc/nova/nova.conf').with(
      'mode'    => '0640',
      'owner'   => 'nova',
      'group'   => 'nova',
      'require' => 'Package[nova-common]'
    )}

    it { should contain_exec('networking-refresh').with(
      'command'     => '/sbin/ifdown -a ; /sbin/ifup -a',
      'refreshonly' => true
    )}

    it { should_not contain_nova_config('sql_connection') }

    it { should contain_nova_config('image_service').with_value('nova.image.glance.GlanceImageService') }
    it { should contain_nova_config('glance_api_servers').with_value('localhost:9292') }

    it { should contain_nova_config('auth_strategy').with_value('keystone') }
    it { should_not contain_nova_config('use_deprecated_auth').with_value('false') }

    it { should contain_nova_config('rabbit_host').with_value('localhost') }
    it { should contain_nova_config('rabbit_password').with_value('guest') }
    it { should contain_nova_config('rabbit_port').with_value('5672') }
    it { should contain_nova_config('rabbit_userid').with_value('guest') }
    it { should contain_nova_config('rabbit_virtual_host').with_value('/') }

    it { should contain_nova_config('verbose').with_value(false) }
    it { should contain_nova_config('logdir').with_value('/var/log/nova') }
    it { should contain_nova_config('state_path').with_value('/var/lib/nova') }
    it { should contain_nova_config('lock_path').with_value('/var/lock/nova') }
    it { should contain_nova_config('service_down_time').with_value('60') }
    it { should contain_nova_config('root_wrap_config').with_value('/etc/nova/rootwrap.conf') }



    describe 'with parameters supplied' do

      let :params do
        {
          'sql_connection'      => 'mysql://user:pass@db/db',
          'verbose'             => true,
          'logdir'              => '/var/log/nova2',
          'image_service'       => 'nova.image.local.LocalImageService',
          'rabbit_host'         => 'rabbit',
          'rabbit_userid'       => 'rabbit_user',
          'rabbit_port'         => '5673',
          'rabbit_password'     => 'password',
          'lock_path'           => '/var/locky/path',
          'state_path'          => '/var/lib/nova2',
          'service_down_time'   => '120',
          'auth_strategy'       => 'foo'
        }
      end

      it { should contain_nova_config('sql_connection').with_value('mysql://user:pass@db/db') }

      it { should contain_nova_config('image_service').with_value('nova.image.local.LocalImageService') }
      it { should_not contain_nova_config('glance_api_servers') }

      it { should contain_nova_config('auth_strategy').with_value('foo') }
      it { should_not contain_nova_config('use_deprecated_auth').with_value(true) }

      it { should contain_nova_config('rabbit_host').with_value('rabbit') }
      it { should contain_nova_config('rabbit_password').with_value('password') }
      it { should contain_nova_config('rabbit_port').with_value('5673') }
      it { should contain_nova_config('rabbit_userid').with_value('rabbit_user') }
      it { should contain_nova_config('rabbit_virtual_host').with_value('/') }

      it { should contain_nova_config('verbose').with_value(true) }
      it { should contain_nova_config('logdir').with_value('/var/log/nova2') }
      it { should contain_nova_config('state_path').with_value('/var/lib/nova2') }
      it { should contain_nova_config('lock_path').with_value('/var/locky/path') }
      it { should contain_nova_config('service_down_time').with_value('120') }

    end

    describe "When platform is RedHat" do
      let :facts do
        {:osfamily => 'RedHat'}
      end
      it { should contain_package('nova-common').with(
        'name'   => 'openstack-nova',
        'ensure' => 'present'
      )}
      it { should contain_nova_config('root_wrap_config').with_value('/etc/nova/rootwrap.conf') }
    end
  end
end
