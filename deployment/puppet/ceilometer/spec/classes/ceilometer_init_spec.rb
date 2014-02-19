require 'spec_helper'

describe 'ceilometer' do

  let :params do
    {
      :metering_secret    => 'metering-s3cr3t',
      :package_ensure     => 'present',
      :verbose            => false,
      :debug              => false,
      :rabbit_host        => '127.0.0.1',
      :rabbit_port        => 5672,
      :rabbit_userid      => 'guest',
      :rabbit_password    => '',
      :rabbit_virtualhost => '/',
    }
  end

  shared_examples_for 'ceilometer' do

    context 'with rabbit_host parameter' do
      it_configures 'a ceilometer base installation'
      it_configures 'rabbit without HA support (with backward compatibility)'
    end

    context 'with rabbit_hosts parameter' do
      context 'with one server' do
        before { params.merge!( :rabbit_hosts => ['127.0.0.1:5672'] ) }
        it_configures 'a ceilometer base installation'
        it_configures 'rabbit without HA support (without backward compatibility)'
      end

      context 'with multiple servers' do
        before { params.merge!( :rabbit_hosts => ['rabbit1:5672', 'rabbit2:5672'] ) }
        it_configures 'a ceilometer base installation'
        it_configures 'rabbit with HA support'
      end
    end
  end

  shared_examples_for 'a ceilometer base installation' do

    it { should include_class('ceilometer::params') }

    it 'configures ceilometer group' do
      should contain_group('ceilometer').with(
        :name    => 'ceilometer',
        :require => 'Package[ceilometer-common]'
      )
    end

    it 'configures ceilometer user' do
      should contain_user('ceilometer').with(
        :name    => 'ceilometer',
        :gid     => 'ceilometer',
        :groups  => ['nova'],
        :system  => true,
        :require => 'Package[ceilometer-common]'
      )
    end

    it 'configures ceilometer configuration folder' do
      should contain_file('/etc/ceilometer/').with(
        :ensure  => 'directory',
        :owner   => 'ceilometer',
        :group   => 'ceilometer',
        :mode    => '0750',
        :require => 'Package[ceilometer-common]'
      )
    end

    it 'configures ceilometer configuration file' do
      should contain_file('/etc/ceilometer/ceilometer.conf').with(
        :owner   => 'ceilometer',
        :group   => 'ceilometer',
        :mode    => '0640',
        :require => 'Package[ceilometer-common]'
      )
    end

    it 'installs ceilometer common package' do
      should contain_package('ceilometer-common').with(
        :ensure => 'present',
        :name   => platform_params[:common_package_name]
      )
    end

    it 'configures required metering_secret' do
      should contain_ceilometer_config('DEFAULT/metering_secret').with_value('metering-s3cr3t')
    end

    context 'without the required metering_secret' do
      before { params.delete(:metering_secret) }
      it { expect { should raise_error(Puppet::Error) } }
    end

    it 'configures rabbit' do
      should contain_ceilometer_config('DEFAULT/rabbit_userid').with_value( params[:rabbit_userid] )
      should contain_ceilometer_config('DEFAULT/rabbit_password').with_value( params[:rabbit_password] )
      should contain_ceilometer_config('DEFAULT/rabbit_virtualhost').with_value( params[:rabbit_virtualhost] )
    end

    it 'configures debug and verbose' do
      should contain_ceilometer_config('DEFAULT/debug').with_value( params[:debug] )
      should contain_ceilometer_config('DEFAULT/verbose').with_value( params[:verbose] )
    end

    it 'fixes a bad value in ceilometer (glance_control_exchange)' do
      should contain_ceilometer_config('DEFAULT/glance_control_exchange').with_value('glance')
    end

    it 'adds glance-notifications topic' do
      should contain_ceilometer_config('DEFAULT/notification_topics').with_value('notifications,glance_notifications')
    end
  end

  shared_examples_for 'rabbit without HA support (with backward compatibility)' do
    it { should contain_ceilometer_config('DEFAULT/rabbit_host').with_value( params[:rabbit_host] ) }
    it { should contain_ceilometer_config('DEFAULT/rabbit_port').with_value( params[:rabbit_port] ) }
    it { should contain_ceilometer_config('DEFAULT/rabbit_hosts').with_value( "#{params[:rabbit_host]}:#{params[:rabbit_port]}" ) }
    it { should contain_ceilometer_config('DEFAULT/rabbit_ha_queues').with_value('false') }
  end

  shared_examples_for 'rabbit without HA support (without backward compatibility)' do
    it { should contain_ceilometer_config('DEFAULT/rabbit_host').with_ensure('absent') }
    it { should contain_ceilometer_config('DEFAULT/rabbit_port').with_ensure('absent') }
    it { should contain_ceilometer_config('DEFAULT/rabbit_hosts').with_value( params[:rabbit_hosts].join(',') ) }
    it { should contain_ceilometer_config('DEFAULT/rabbit_ha_queues').with_value('false') }
  end

  shared_examples_for 'rabbit with HA support' do
    it { should contain_ceilometer_config('DEFAULT/rabbit_host').with_ensure('absent') }
    it { should contain_ceilometer_config('DEFAULT/rabbit_port').with_ensure('absent') }
    it { should contain_ceilometer_config('DEFAULT/rabbit_hosts').with_value( params[:rabbit_hosts].join(',') ) }
    it { should contain_ceilometer_config('DEFAULT/rabbit_ha_queues').with_value('true') }
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :common_package_name => 'ceilometer-common' }
    end

    it_configures 'ceilometer'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :common_package_name => 'openstack-ceilometer-common' }
    end

    it_configures 'ceilometer'
  end
end
