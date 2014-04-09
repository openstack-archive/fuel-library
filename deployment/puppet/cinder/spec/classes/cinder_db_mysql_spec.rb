require 'spec_helper'

describe 'cinder::db::mysql' do

  let :req_params do
    {:password => 'pw',
     :mysql_module => '0.9'}
  end

  let :facts do
    {:osfamily => 'Debian'}
  end

  let :pre_condition do
    'include mysql::server'
  end

  describe 'with only required params' do
    let :params do
      req_params
    end
    it { should contain_mysql__db('cinder').with(
      :user         => 'cinder',
      :password     => 'pw',
      :host         => '127.0.0.1',
      :charset      => 'utf8'
     ) }
  end
  describe "overriding allowed_hosts param to array" do
    let :params do
      {
        :password       => 'cinderpass',
        :allowed_hosts  => ['127.0.0.1','%']
      }
    end

    it {should_not contain_cinder__db__mysql__host_access("127.0.0.1").with(
      :user     => 'cinder',
      :password => 'cinderpass',
      :database => 'cinder'
    )}
    it {should contain_cinder__db__mysql__host_access("%").with(
      :user     => 'cinder',
      :password => 'cinderpass',
      :database => 'cinder'
    )}
  end
  describe "overriding allowed_hosts param to string" do
    let :params do
      {
        :password       => 'cinderpass2',
        :allowed_hosts  => '192.168.1.1'
      }
    end

    it {should contain_cinder__db__mysql__host_access("192.168.1.1").with(
      :user     => 'cinder',
      :password => 'cinderpass2',
      :database => 'cinder'
    )}
  end

  describe "overriding allowed_hosts param equals to host param " do
    let :params do
      {
        :password       => 'cinderpass2',
        :allowed_hosts  => '127.0.0.1'
      }
    end

    it {should_not contain_cinder__db__mysql__host_access("127.0.0.1").with(
      :user     => 'cinder',
      :password => 'cinderpass2',
      :database => 'cinder'
    )}
  end
end
