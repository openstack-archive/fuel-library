require 'spec_helper'

describe 'glance::db::mysql' do
  let :facts do
    {
      :osfamily => 'Debian'
    }
  end

  let :pre_condition do
    'include mysql::server'
  end

  describe "with default params" do
    let :params do
      {
        :password => 'glancepass1',
        :mysql_module => '0.9'
      }
    end

    it { should contain_class('mysql::python') }

    it { should contain_mysql__db('glance').with(
      :password => 'glancepass1',
      :require  => 'Class[Mysql::Config]',
      :charset  => 'utf8'
    )}

  end

  describe "overriding default params" do
    let :params do
      {
        :password       => 'glancepass2',
        :dbname         => 'glancedb2',
        :charset        => 'utf8',
      }
    end

    it { should contain_mysql__db('glancedb2').with(
      :password => 'glancepass2',
      :charset  => 'utf8'
    )}

  end

  describe "overriding allowed_hosts param to array" do
    let :params do
      {
        :password       => 'glancepass2',
        :dbname         => 'glancedb2',
        :allowed_hosts  => ['127.0.0.1','%']
      }
    end

    it {should_not contain_glance__db__mysql__host_access("127.0.0.1").with(
      :user     => 'glance',
      :password => 'glancepass2',
      :database => 'glancedb2'
    )}
    it {should contain_glance__db__mysql__host_access("%").with(
      :user     => 'glance',
      :password => 'glancepass2',
      :database => 'glancedb2'
    )}

  end

  describe "overriding allowed_hosts param to string" do
    let :params do
      {
        :password       => 'glancepass2',
        :dbname         => 'glancedb2',
        :allowed_hosts  => '192.168.1.1'
      }
    end

    it {should contain_glance__db__mysql__host_access("192.168.1.1").with(
      :user     => 'glance',
      :password => 'glancepass2',
      :database => 'glancedb2'
    )}
  end

  describe "overriding allowed_hosts param equals to host param " do
    let :params do
      {
        :password       => 'glancepass2',
        :dbname         => 'glancedb2',
        :allowed_hosts  => '127.0.0.1'
      }
    end

    it {should_not contain_glance__db__mysql__host_access("127.0.0.1").with(
      :user     => 'glance',
      :password => 'glancepass2',
      :database => 'glancedb2'
    )}
  end

end
