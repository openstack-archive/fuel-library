require 'spec_helper'

describe 'openstacklib::db::mysql::host_access' do

  let :pre_condition do
    "include mysql::server\n" +
    "openstacklib::db::mysql { 'nova':\n" +
    "  password_hash => 'AA1420F182E88B9E5F874F6FBE7459291E8F4601'}"
  end

  shared_examples 'openstacklib::db::mysql::host_access examples' do

    context 'with required parameters' do
      let (:title) { 'nova_10.0.0.1' }
      let :params do
        { :user          => 'foobar',
          :password_hash => 'AA1420F182E88B9E5F874F6FBE7459291E8F4601',
          :database      => 'nova',
          :privileges    => 'ALL' }
      end

      it { should contain_mysql_user("#{params[:user]}@10.0.0.1").with(
        :password_hash => params[:password_hash]
      )}

      it { should contain_mysql_grant("#{params[:user]}@10.0.0.1/#{params[:database]}.*").with(
        :user       => "#{params[:user]}@10.0.0.1",
        :privileges => 'ALL',
        :table      => "#{params[:database]}.*"
      )}
    end

  end

  context 'on a Debian osfamily' do
    let :facts do
      { :osfamily => "Debian" }
    end

    include_examples 'openstacklib::db::mysql::host_access examples'
  end

  context 'on a RedHat osfamily' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    include_examples 'openstacklib::db::mysql::host_access examples'
  end
end
