require 'spec_helper'

describe 'nova::db::mysql' do

  let :pre_condition do
    'include mysql::server'
  end

  let :required_params do
    { :password => "qwerty" }
  end

  context 'on a Debian osfamily' do
    let :facts do
      { :osfamily => "Debian" }
    end

    context 'with only required parameters' do
      let :params do
        required_params
      end

      it { should contain_mysql__db('nova').with(
        :user        => 'nova',
        :password    => 'qwerty',
        :charset     => 'latin1',
        :require     => "Class[Mysql::Config]"
      )}
    end

    context 'when overriding charset' do
      let :params do
        { :charset => 'utf8' }.merge(required_params)
      end

      it { should contain_mysql__db('nova').with_charset(params[:charset]) }
    end
  end

  context 'on a RedHat osfamily' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    context 'with only required parameters' do
      let :params do
        required_params
      end

      it { should contain_mysql__db('nova').with(
        :user        => 'nova',
        :password    => 'qwerty',
        :charset     => 'latin1',
        :require     => "Class[Mysql::Config]"
      )}
    end

    context 'when overriding charset' do
      let :params do
        { :charset => 'utf8' }.merge(required_params)
      end

      it { should contain_mysql__db('nova').with_charset(params[:charset]) }
    end
  end

  describe "overriding allowed_hosts param to array" do
    let :facts do
      { :osfamily => "Debian" }
    end
    let :params do
      {
        :password       => 'novapass',
        :allowed_hosts  => ['127.0.0.1','%']
      }
    end

    it {should_not contain_nova__db__mysql__host_access("127.0.0.1").with(
      :user     => 'nova',
      :password => 'novapass',
      :database => 'nova'
    )}
    it {should contain_nova__db__mysql__host_access("%").with(
      :user     => 'nova',
      :password => 'novapass',
      :database => 'nova'
    )}
  end

  describe "overriding allowed_hosts param to string" do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    let :params do
      {
        :password       => 'novapass2',
        :allowed_hosts  => '192.168.1.1'
      }
    end

    it {should contain_nova__db__mysql__host_access("192.168.1.1").with(
      :user     => 'nova',
      :password => 'novapass2',
      :database => 'nova'
    )}
  end

  describe "overriding allowed_hosts param equals to host param " do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    let :params do
      {
        :password       => 'novapass2',
        :allowed_hosts  => '127.0.0.1'
      }
    end

    it {should_not contain_nova__db__mysql__host_access("127.0.0.1").with(
      :user     => 'nova',
      :password => 'novapass2',
      :database => 'nova'
    )}
  end
end
