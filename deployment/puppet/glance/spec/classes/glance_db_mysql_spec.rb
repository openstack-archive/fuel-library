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
      }
    end

    it { should contain_openstacklib__db__mysql('glance').with(
      :password_hash => '*41C910F70EB213CF4CB7B2F561B4995503C0A87B',
      :charset       => 'utf8'
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

    it { should contain_openstacklib__db__mysql('glance').with(
      :password_hash => '*6F9A1CB9BD83EE06F3903BDFF9F4188764E694CA',
      :dbname        => 'glancedb2',
      :charset       => 'utf8'
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

  end

  describe "overriding allowed_hosts param to string" do
    let :params do
      {
        :password       => 'glancepass2',
        :dbname         => 'glancedb2',
        :allowed_hosts  => '192.168.1.1'
      }
    end

  end

  describe "overriding allowed_hosts param equals to host param " do
    let :params do
      {
        :password       => 'glancepass2',
        :dbname         => 'glancedb2',
        :allowed_hosts  => '127.0.0.1'
      }
    end

  end

end
