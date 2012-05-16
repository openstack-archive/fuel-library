require 'spec_helper'

describe 'nova::db::mysql' do
  let :facts do 
    { :osfamily => "Debian" }
  end
  let :params do
    { :password => "qwerty" }
  end
  it { should contain_mysql__db('nova').with(
      :user        => 'nova',
      :password    => 'qwerty',
      :require     => "Class[Mysql::Config]"
  )}

end
