require 'spec_helper'

describe 'osnailyfacter::apache' do
  let :facts do
    {
      :osfamily               => 'Debian',
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '14.04',
      :concat_basedir         => '/var/lib/puppet/concat'
    }
  end

  let :params do
    {
      :log_formats => {
        'forwarded' => '%{X-Forwarded-For}i %l %u %t \"%r\" %s %b \"%{Referer}i\" \"%{User-agent}i\"'
      }
    }
  end

  let :file_default_opts do
    {
      :ensure  => 'file',
      :owner   => 'root',
      :group   => 'root',
      :mode    => '0755',
    }
  end

  it 'should configure apache to listen default 80 port' do
     is_expected.to contain_apache__listen('80')
  end

  it 'should have apache class' do
    is_expected.to contain_class('apache').with(
      :server_tokens    => 'Prod',
      :server_signature => 'Off',
      :trace_enable     => 'Off',
      :log_formats      => params[:log_formats],
    )
  end

  it 'should have logrotate apache config' do
    is_expected.to contain_file('/etc/logrotate.d/apache2').with(
      file_default_opts.merge(
        :mode    => '0644',
        :require => 'Package[httpd]',
      )
    )
  end

  it 'should have a httpd prerotate folder' do
    is_expected.to contain_file('/etc/logrotate.d/httpd-prerotate').with(
      file_default_opts.merge(
        :ensure => 'directory',
      )
    )
  end

  it 'should have a httpd prerotate config' do
    is_expected.to contain_file('/etc/logrotate.d/httpd-prerotate/apache2').with(
      file_default_opts
    )
  end
end

