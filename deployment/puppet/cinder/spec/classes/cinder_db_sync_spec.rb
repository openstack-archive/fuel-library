require 'spec_helper'

describe 'cinder::db::sync' do

  let :facts do
    {:osfamily => 'Debian'}
  end
  it { should contain_exec('cinder-manage db_sync').with(
    :command     => 'cinder-manage db sync',
    :path        => '/usr/bin',
    :user        => 'cinder',
    :refreshonly => true,
    :logoutput   => 'on_failure'
  ) }

end
