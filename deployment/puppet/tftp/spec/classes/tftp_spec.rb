require 'spec_helper'
describe 'tftp', :type => :class do

  describe 'when deploying on debian as standalone' do
    let(:facts) { { :operatingsystem  => 'Debian',
                    :osfamily         => 'Debian',
                    :path             => '/usr/local/bin:/usr/bin:/bin', } }
    let(:params) { {  :inetd  => false, } }
    it {
      should contain_file('/etc/default/tftpd-hpa')
      should contain_package('tftpd-hpa')
      should contain_service('tftpd-hpa').with({
        'ensure'    => 'running',
        'enable'    => true,
        'hasstatus' => false,
        'provider'  => nil,
      })
    }
  end

  describe 'when deploying on ubuntu as standalone' do
    let(:facts) { { :operatingsystem  => 'Ubuntu',
                    :osfamily         => 'Debian',
                    :path             => '/usr/local/bin:/usr/bin:/bin', } }
    let(:params) { {  :inetd  => false, } }
    it {
      should contain_package('tftpd-hpa')
      should contain_file('/etc/default/tftpd-hpa')
      should contain_service('tftpd-hpa').with({
        'ensure'    => 'running',
        'enable'    => true,
        'hasstatus' => true,
        'provider'  => 'upstart',
      })
    }
  end

  describe 'when deploying on redhat family as standalone' do
    let (:facts) { {  :osfamily         => 'RedHat',
                      :path             => '/usr/local/bin:/usr/bin:/bin', } }
    let(:params) { {  :inetd  => false, } }
    it {
      should contain_package('tftpd-hpa').with({
        'name'      => 'tftp-server',
    })

      should contain_service('tftpd-hpa').with({
        'ensure'    => 'running',
        'enable'    => 'true',
        'hasstatus' => false,
        'provider'  => 'base',
        'start'     => '/usr/sbin/in.tftpd -l -a 0.0.0.0:69 -u nobody --secure /var/lib/tftpboot',
      })
    }
  end

  describe 'when deploying on redhat family with custom options as standalone' do
    let (:facts) { {  :osfamily         => 'RedHat',
                      :path             => '/usr/local/bin:/usr/bin:/bin', } }
    let (:params) { { :address          => '127.0.0.1',
                      :port             => '1069',
                      :inetd            => false,
                      :username         => 'root',
                      :options          => '--secure --timeout 50',
                      :directory        => '/tftpboot', } }

    it {
      should contain_package('tftpd-hpa').with({
        'name'      => 'tftp-server',
      })

      should contain_service('tftpd-hpa').with({
        'ensure'    => 'running',
        'enable'    => 'true',
        'hasstatus' => false,
        'provider'  => 'base',
        'start'     => '/usr/sbin/in.tftpd -l -a 127.0.0.1:1069 -u root --secure --timeout 50 /tftpboot',
      })
    }
  end

  describe 'when deploying with xinetd on redhat family' do
    let (:facts) { {  :osfamily => 'Redhat',
                      :path     => '/usr/local/bin:/usr/bin:/bin', } }
    it {
      should contain_class('xinetd')
      should contain_service('tftpd-hpa').with({
        'ensure'      => 'stopped',
        'enable'      => false,
    })
      should contain_xinetd__service('tftp').with({
        'port'        => '69',
        'protocol'    => 'udp',
        'server_args' => '--secure -u nobody /var/lib/tftpboot',
        'server'      => '/usr/sbin/in.tftpd',
        'socket_type' => 'dgram',
        'cps'         => '100 2',
        'flags'       => 'IPv4',
        'per_source'   => '11',
        'wait'        => 'yes',
      })
    }
  end

  describe 'when deploying with xinetd on ubuntu' do
    let (:facts) { {  :osfamily         => 'Debian',
                      :operatingsystem  => 'Ubuntu',
                      :path     => '/usr/local/bin:/usr/bin:/bin', } }
    it {
      should contain_class('xinetd')
      should contain_service('tftpd-hpa').with({
        'ensure'      => 'stopped',
        'enable'      => false,
      })
      should contain_xinetd__service('tftp').with({
        'port'        => '69',
        'protocol'    => 'udp',
        'server_args' => '--secure -u tftp /var/lib/tftpboot',
        'server'      => '/usr/sbin/in.tftpd',
        'socket_type' => 'dgram',
        'cps'         => '100 2',
        'flags'       => 'IPv4',
        'per_source'   => '11',
        'wait'        => 'yes',
      })
    }
  end

  describe 'when deploying with xinetd on debian' do
    let (:facts) { {  :osfamily         => 'Debian',
                      :operatingsystem  => 'Debian',
                      :path     => '/usr/local/bin:/usr/bin:/bin', } }
    it {
      should contain_class('xinetd')
      should contain_xinetd__service('tftp').with({
        'port'        => '69',
        'protocol'    => 'udp',
        'server_args' => '--secure -u tftp /srv/tftp',
        'server'      => '/usr/sbin/in.tftpd',
        'socket_type' => 'dgram',
        'cps'         => '100 2',
        'flags'       => 'IPv4',
        'per_source'  => '11',
        'wait'        => 'yes',
        'bind'        => '0.0.0.0',
      })
    }
  end

  describe 'when deploying with xinetd with custom options' do
    let (:facts) { {  :osfamily         => 'Debian',
                      :operatingsystem  => 'Debian',
                      :path     => '/usr/local/bin:/usr/bin:/bin', } }
    let (:params) { { :options  => '--secure --timeout 50', } }
    it {
      should contain_class('xinetd')
      should contain_xinetd__service('tftp').with({
        'port'        => '69',
        'protocol'    => 'udp',
        'server_args' => '--secure --timeout 50 -u tftp /srv/tftp',
        'server'      => '/usr/sbin/in.tftpd',
        'socket_type' => 'dgram',
        'cps'         => '100 2',
        'flags'       => 'IPv4',
        'per_source'  => '11',
        'wait'        => 'yes',
        'bind'        => '0.0.0.0',
      })
    }
  end

  describe 'when deploying with xinetd with custom settings' do
    let (:facts) { {  :osfamily         => 'Debian',
                      :operatingsystem  => 'Debian',
                      :path       => '/usr/local/bin:/usr/bin:/bin', } }
    let (:params) { { :port       => 1069,
                      :address    => '127.0.0.1',
                      :username   => 'root',
                      :directory  => '/tftpboot', } }
    it {
      should contain_class('xinetd')
      should contain_xinetd__service('tftp').with({
        'port'        => '1069',
        'protocol'    => 'udp',
        'server_args' => '--secure -u root /tftpboot',
        'server'      => '/usr/sbin/in.tftpd',
        'socket_type' => 'dgram',
        'cps'         => '100 2',
        'flags'       => 'IPv4',
        'per_source'   => '11',
        'wait'        => 'yes',
        'bind'        => '127.0.0.1',
      })
    }
  end

end
