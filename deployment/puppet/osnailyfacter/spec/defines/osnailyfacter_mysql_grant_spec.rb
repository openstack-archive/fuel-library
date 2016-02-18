require 'spec_helper'

describe 'osnailyfacter::mysql_grant' do
  let(:title) { 'localhost' }

  let :facts do
    {
      :osfamily               => 'Debian',
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '14.04',
      :concat_basedir         => '/var/lib/puppet/concat'
    }
  end


  context 'with defaults' do

    let(:params) do
      { :user => 'root' }
    end

    it 'should include mysql grant for localhost by default' do
      is_expected.to contain_mysql_grant('root@localhost/*.*').with(
        :user => 'root@localhost',
        :options => ['GRANT'],
        :privileges => ['ALL']
      )
    end
  end
end

