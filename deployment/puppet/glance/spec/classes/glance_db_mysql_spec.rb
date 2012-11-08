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
      	:password => 'glancepass1'
      }
    end

  	it { should include_class('mysql::python') }

    it { should contain_mysql__db('glance').with(
      :password => 'glancepass1',
      :require  => 'Class[Mysql::Config]',
      :charset  => 'latin1'
    )}

  end

  describe "overriding default params" do
    let :params do
      {
      	:password => 'glancepass2',
      	:dbname   => 'glancedb2',
      	:charset  => 'utf8'
      }
    end

    it { should contain_mysql__db('glancedb2').with(
      :password => 'glancepass2',
      :charset  => 'utf8'
    )}

  end

end
