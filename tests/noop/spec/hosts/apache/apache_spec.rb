# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'apache/apache.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should have osnailyfacter::apache class' do
      should contain_class('osnailyfacter::apache').with(
        :purge_configs => false,
        :listen_ports  => Noop.hiera_array('apache_ports', ['0.0.0.0:80']),
        :log_formats   => {
          'combined'  => '%h %l %u %{%d/%b/%Y:%T}t.%{msec_frac}t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"',
          'common'    => '%h %l %u %{%d/%b/%Y:%T}t.%{msec_frac}t \"%r\" %>s %b',
          'forwarded' =>  '%{X-Forwarded-For}i %l %u %{%d/%b/%Y:%T}t.%{msec_frac}t \"%r\" %s %b \"%{Referer}i\" \"%{User-agent}i\"'
        }
      )
    end

    it 'should execute apache class with given parameters' do
      should contain_class('apache').with(
        'mpm_module'       => 'false',
        'default_vhost'    => 'false',
        'server_tokens'    => 'Prod',
        'server_signature' => 'Off',
        'trace_enable'     => 'Off'
      )
    end
    it 'should apply kernel tweaks for connections' do
      should contain_sysctl__value('net.core.somaxconn').with_value('4096')
      should contain_sysctl__value('net.ipv4.tcp_max_syn_backlog').with_value('8192')
    end

    it {
      should contain_service('httpd').with(
           'hasrestart' => nil,
           'restart'    => nil,
      )
    }

    it 'should contain apache2 logrotate overrides' do
      should contain_file('/etc/logrotate.d/apache2').with(
        :ensure => 'file',
        :owner  => 'root',
        :group  => 'root',
        :mode   => '0644').with_content(/rotate 52/)
      should contain_file('/etc/logrotate.d/httpd-prerotate').with(
        :ensure => 'directory',
        :owner  => 'root',
        :group  => 'root',
        :mode   => '0755')
      should contain_file('/etc/logrotate.d/httpd-prerotate/apache2').with(
        :ensure => 'file',
        :owner  => 'root',
        :group  => 'root',
        :mode   => '0755').with_content(/^sleep \d+/)
    end

    it 'should not purge config files' do
      should contain_class('apache').with(
        'purge_configs' => 'false',
      )
    end
  end
  test_ubuntu_and_centos manifest
end
