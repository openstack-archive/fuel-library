require 'spec_helper'

describe 'tftp::file' do

  let(:title) { 'sample' }

  describe 'when deploying on debian' do
    let(:facts) { { :operatingsystem => 'Debian',
                    :osfamily        => 'Debian',
                    :path            => '/usr/local/bin:/usr/bin:/bin', } }

    it {
      should contain_class('tftp')
      should contain_file('/srv/tftp/sample').with({
        'ensure'  => 'file',
        'owner'   => 'tftp',
        'group'   => 'tftp',
        'mode'    => '0644',
        'recurse' => false,
      })
    }
  end

  describe 'when deploying on ubuntu' do
    let(:facts) { { :operatingsystem => 'ubuntu',
                    :osfamily        => 'Debian',
                    :path            => '/usr/local/bin:/usr/bin:/bin', } }

    it {
      should contain_class('tftp')
      should contain_file('/var/lib/tftpboot/sample').with({
        'ensure'  => 'file',
        'owner'   => 'tftp',
        'group'   => 'tftp',
        'mode'    => '0644',
        'recurse' => false,
      })
    }
  end

  describe 'when deploying on redhat' do
    let(:facts) { { :operatingsystem => 'RedHat',
                    :osfamily        => 'redhat',
                    :path            => '/usr/local/bin:/usr/bin:/bin', } }

    it {
      should contain_class('tftp')
      should contain_file('/var/lib/tftpboot/sample').with({
        'ensure'  => 'file',
        'owner'   => 'nobody',
        'group'   => 'nobody',
        'mode'    => '0644',
        'recurse' => false,
      })
    }
  end

  describe 'when deploying with parameters' do
    let(:params) { {:ensure => 'directory',
                    :owner  => 'root',
                    :group  => 'root',
                    :mode   => '0755',
                    :recurse => true }}
    let(:facts) { { :operatingsystem => 'Debian',
                    :osfamily        => 'Debian',
                    :path            => '/usr/local/bin:/usr/bin:/bin', } }

    it {
      should contain_class('tftp')
      should contain_file('/srv/tftp/sample').with({
        'ensure'  => 'directory',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755',
        'recurse' => true,
      })
    }
  end

  describe 'when deploying without recurse parameters' do
    let(:facts) { {:operatingsystem => 'Debian',
                   :osfamily        => 'Debian',
                   :path            => '/usr/local/bin:/usr/bin:/bin', } }

    it {
      should contain_class('tftp')
      should contain_file('/srv/tftp/sample').with({
        'ensure'       => 'file',
        'recurse'      => false,
        'purge'        => nil,
        'replace'      => nil,
        'recurselimit' => nil,
      })
    }
  end

  describe 'when deploying with recurse parameters' do
    let(:params) { {:ensure       => 'directory',
                    :mode         => '0755',
                    :recurse      => true,
                    :recurselimit => 42,
                    :purge        => true,
                    :replace      => false }}
    let(:facts) { {:operatingsystem => 'Debian',
                   :osfamily        => 'Debian',
                   :path            => '/usr/local/bin:/usr/bin:/bin', }}

    it {
      should contain_class('tftp')
      should contain_file('/srv/tftp/sample').with({
        'ensure'       => 'directory',
        'owner'        => 'tftp',
        'group'        => 'tftp',
        'mode'         => '0755',
        'recurse'      => true,
        'recurselimit' => 42,
        'purge'        => true,
        'replace'      => false,
      })
    }
  end

  describe 'when deploying directory' do
    let(:params) { {:ensure => 'directory',
                    :mode   => '0755' }}
    let(:facts) { { :operatingsystem    => 'Debian',
                    :osfamily           => 'Debian',
                    :caller_module_name => 'acme',
                    :path               => '/usr/local/bin:/usr/bin:/bin', } }

    it {
      should contain_class('tftp')
      should contain_file('/srv/tftp/sample').with({
        'ensure' => 'directory',
        'mode'   => '0755',
        'source' => nil,
      })
    }
  end

  describe 'when deploying file' do
    let(:params) { {:ensure => 'file',
                    :mode   => '0755' }}
    let(:facts) { { :operatingsystem    => 'Debian',
                    :osfamily           => 'Debian',
                    :path               => '/usr/local/bin:/usr/bin:/bin', } }

    it {
      should contain_class('tftp')
      should contain_file('/srv/tftp/sample').with({
        'ensure' => 'file',
        'mode'   => '0755',
        'source' => 'puppet:///modules/tftp/sample'
      })
    }
  end

  describe 'when deploying file with content' do
    let(:params) { {:ensure  => 'file',
                    :content => 'hi',
                    :mode    => '0755' }}
    let(:facts) { { :operatingsystem    => 'Debian',
                    :osfamily           => 'Debian',
                    :caller_module_name => 'acme',
                    :path               => '/usr/local/bin:/usr/bin:/bin', } }
    it {
      should contain_class('tftp')
      should contain_file('/srv/tftp/sample').with({
        'ensure'  => 'file',
        'mode'    => '0755',
        'content' => 'hi',
        'source'  => nil,
      })
    }
  end

end
