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

      it { is_expected.to contain_openstacklib__db__mysql('nova').with(
        :user          => 'nova',
        :password_hash => '*AA1420F182E88B9E5F874F6FBE7459291E8F4601',
        :charset       => 'utf8',
        :collate       => 'utf8_general_ci',
      )}
    end

    context 'when overriding charset' do
      let :params do
        { :charset => 'latin1' }.merge(required_params)
      end

      it { is_expected.to contain_openstacklib__db__mysql('nova').with_charset(params[:charset]) }
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

      it { is_expected.to contain_openstacklib__db__mysql('nova').with(
        :user          => 'nova',
        :password_hash => '*AA1420F182E88B9E5F874F6FBE7459291E8F4601',
        :charset       => 'utf8',
        :collate       => 'utf8_general_ci',
      )}
    end

    context 'when overriding charset' do
      let :params do
        { :charset => 'latin1' }.merge(required_params)
      end

      it { is_expected.to contain_openstacklib__db__mysql('nova').with_charset(params[:charset]) }
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

  end
end
