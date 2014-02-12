require 'spec_helper'

describe 'zabbix::frontend' do

  # only support gentoo for frontends as of now
  let(:facts) {
    {
      :operatingsystem => 'Gentoo',
    }
  }
  context "on gentoo" do
    let(:facts) { 
      {
        :fqdn            => 'f.q.d.n.example.com',
        :operatingsystem => 'Gentoo',
      }
    }
    let(:params) {
      {
        :ensure  => 'present',
        :version => '2.0.3',
      }
    }
    it {
      should contain_class('zabbix::frontend::gentoo').with({
        :ensure  => 'present',
      })
      should contain_class('zabbix::frontend::vhost').with({
        :ensure   => 'present',
        :hostname => 'f.q.d.n.example.com'
      })
      should contain_webapp_config('zabbix').with({
        :action  => 'install', 
        :vhost   => 'f.q.d.n.example.com',
        :base    => '/zabbix', 
        :app     => 'zabbix', 
        :version => '2.0.3',
      })
    }
  end
  
  context "use host parameter" do
    let(:facts) {
      {
        :operatingsystem => 'Gentoo',
        :fqdn => 'one.local'
      }
    }
    let(:params) {
      {
        :hostname => 'two.local'
      }
    }
    it {
      should contain_webapp_config('zabbix').with({
        :vhost => 'two.local'
      })
      }
  end

  context 'it should use hiera' do
    let(:hieradata) { 
      { :frontend_base => '/yessss' }
    }
    it {
      should contain_webapp_config('zabbix').with({
        :base => '/yessss'
      })
    }
  end
  
  context "use base uri parameter" do
    let(:params) {
      {
        :base => '/mah_zahbowx'
      }
    }
    it {
      should contain_webapp_config('zabbix').with({
        :base => '/mah_zahbowx'
      })
    }
  end
  
  context "configure frontend" do

    let(:facts) { 
      {
        :fqdn            => 'f.q.d.n.example.com',
        :operatingsystem => 'Gentoo',
      }
    }
    let(:params) {
      {
        :ensure  => 'present',
        :version => '2.0.3',
      }
    }
    it {
      should contain_file('/var/www/f.q.d.n.example.com/htdocs/zabbix/conf/zabbix.conf.php')
    }
  end
  
  context "grab version to install from facter" do

    let(:facts) { 
      {
        :fqdn            => 'f.q.d.n.example.com',
        :operatingsystem => 'Gentoo',
        :zabbixversion   => 'over9000'
      }
    }
    it {
      should contain_webapp_config('zabbix').with({
        :version => 'over9000',
      })
    }
  end
end
