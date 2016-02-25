require 'spec_helper'

describe 'osnailyfacter::mysql_grant' do

  let :facts do
    {
      :osfamily               => 'Debian',
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '14.04',
      :concat_basedir         => '/var/lib/puppet/concat'
    }
  end


  context 'with defaults' do
    let(:title) { 'localhost' }

    let(:params) do
      { :user => 'root' }
    end

    it 'should include mysql grant for localhost by default' do
      is_expected.to contain_mysql_user('root@localhost').with(
        :password_hash => ''
      )
      is_expected.to contain_mysql_grant('root@localhost/*.*').with(
        :user => 'root@localhost',
        :table => '*.*',
        :options => ['GRANT'],
        :privileges => ['ALL']
      )
    end
  end

  context 'with specific database and table' do
    let(:title) { 'localhost' }

    let(:params) do
      {
        :user => 'root',
        :database => 'testing',
        :table => 'testing'
      }
    end

    it 'should include mysql grant for localhost by default' do
      is_expected.to contain_mysql_user('root@localhost').with(
        :password_hash => ''
      )
      is_expected.to contain_mysql_grant('root@localhost/testing.testing').with(
        :user => 'root@localhost',
        :table => 'testing.testing',
        :options => ['GRANT'],
        :privileges => ['ALL']
      )
    end
  end

  context 'with specific custom privileges' do
    let(:title) { 'localhost' }

    let(:params) do
      {
        :user => 'root',
        :options => '',
        :privileges => ['SELECT']
      }
    end

    it 'should include mysql grant for localhost by default' do
      is_expected.to contain_mysql_user('root@localhost').with(
        :password_hash => ''
      )
      is_expected.to contain_mysql_grant('root@localhost/*.*').with(
        :user => 'root@localhost',
        :table => '*.*',
        :options => '',
        :privileges => ['SELECT']
      )
    end
  end
end

