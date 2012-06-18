require 'spec_helper'

describe 'horizon' do
  let :params do
    {
      'cache_server_ip' => '10.0.0.1'
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
  end
end
