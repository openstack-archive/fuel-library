require 'spec_helper'

describe 'nova::db::mysql' do

  context 'on a Debian osfamily' do
    let :facts do
      { :osfamily => "Debian" }
    end
    let :params do
      { :password => "qwerty" }
    end
    it { should contain_mysql__db('nova').with(
      :user        => 'nova',
      :password    => 'qwerty',
      :charset     => 'latin1',
      :require     => "Class[Mysql::Config]"
    )}
  end

  context 'on a RedHat osfamily' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    let :params do
      { :password => 'qwerty' }
    end
    it { should contain_mysql__db('nova').with(
      :user        => 'nova',
      :password    => 'qwerty',
      :charset     => 'latin1',
      :require     => "Class[Mysql::Config]"
    )}
  end
end
