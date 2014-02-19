require 'spec_helper'

describe 'horizon' do
  let :params do
    {
      'cache_server_ip' => '10.0.0.1',
      'secret_key'      => 'elj1IWiLoWHgcyYxFVLj7cM5rGOOxWl0'
    }
  end

  describe 'when running on redhat' do
    let :facts do
      {
        'osfamily' => 'RedHat'
      }
    end

    it {
      should contain_service('httpd').with_name('httpd')
    }
  end

  describe 'when running on debian' do
    let :facts do
      {
        'osfamily' => 'Debian'
      }
    end

    it {
      should contain_service('httpd').with_name('apache2')
    }

    describe 'with default parameters' do
      it { should contain_file('/etc/openstack-dashboard/local_settings.py').with_content(/^SECRET_KEY = 'elj1IWiLoWHgcyYxFVLj7cM5rGOOxWl0'$/) }
      it { should contain_file('/etc/openstack-dashboard/local_settings.py').with_content(/^OPENSTACK_HOST = "127.0.0.1"$/) }
      it { should contain_file('/etc/openstack-dashboard/local_settings.py').with_content(/^OPENSTACK_KEYSTONE_URL = "http:\/\/%s:5000\/v2.0" % OPENSTACK_HOST$/) }
      it { should contain_file('/etc/openstack-dashboard/local_settings.py').with_content(/^OPENSTACK_KEYSTONE_DEFAULT_ROLE = "Member"$/) }
      it { should contain_file('/etc/openstack-dashboard/local_settings.py').with_content(/^DEBUG = False$/) }
      it { should contain_file('/etc/openstack-dashboard/local_settings.py').with_content(/^API_RESULT_LIMIT = 1000$/) }
    end

    describe 'when overriding parameters' do
      let :params do
        {
          :secret_key            => 'dummy',
          :cache_server_ip       => '10.0.0.1',
          :keystone_host         => 'keystone.example.com',
          :keystone_port         => 4682,
          :keystone_scheme       => 'https',
          :keystone_default_role => 'SwiftOperator',
          :django_debug          => true,
          :api_result_limit      => 4682,
        }
      end

      it { should contain_file('/etc/openstack-dashboard/local_settings.py').with_content(/^SECRET_KEY = 'dummy'$/) }
      it { should contain_file('/etc/openstack-dashboard/local_settings.py').with_content(/^OPENSTACK_HOST = "keystone.example.com"$/) }
      it { should contain_file('/etc/openstack-dashboard/local_settings.py').with_content(/^OPENSTACK_KEYSTONE_URL = "https:\/\/%s:4682\/v2.0" % OPENSTACK_HOST$/) }
      it { should contain_file('/etc/openstack-dashboard/local_settings.py').with_content(/^OPENSTACK_KEYSTONE_DEFAULT_ROLE = "SwiftOperator"$/) }
      it { should contain_file('/etc/openstack-dashboard/local_settings.py').with_content(/^DEBUG = True$/) }
      it { should contain_file('/etc/openstack-dashboard/local_settings.py').with_content(/^API_RESULT_LIMIT = 4682$/) }
    end
  end
end
