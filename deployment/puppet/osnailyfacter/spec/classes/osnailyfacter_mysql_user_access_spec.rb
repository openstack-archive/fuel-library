require 'spec_helper'

describe 'osnailyfacter::mysql_user_access' do
  let :facts do
    {
      :osfamily               => 'Debian',
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '14.04',
      :concat_basedir         => '/var/lib/puppet/concat'
    }
  end


  context 'with defaults' do
    let :params do
      { :db_user => 'root' }
    end
    it 'should include mysql grant for localhost by default' do
      is_expected.to contain_osnailyfacter__mysql_grant('localhost').with(
        :user => 'root'
      )
    end
  end

  context 'with custom user' do
    let :params do
      { :db_user => 'osnailyfacter' }
    end
    it 'should include mysql grant for localhost by default' do
      is_expected.to contain_osnailyfacter__mysql_grant('localhost').with(
        :user => 'osnailyfacter'
      )
    end
  end

  context 'with custom host list' do
    let :params do
      {
        :db_user => 'root',
        :access_networks => ['1.1.1.1', '2.2.2.2']
      }
    end
    it 'should include mysql grant for all networks provided' do
      params[:access_networks].each do |net|
       is_expected.to contain_osnailyfacter__mysql_grant(net).with(
         :user => 'root'
       )
      end
    end
  end
end

