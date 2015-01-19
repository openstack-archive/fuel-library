require 'spec_helper'

describe 'apache::mod::proxy_connect', :type => :class do
  let :pre_condition do
    [
      'include apache',
      'include apache::mod::proxy',
      'include apache::mod::proxy_connect'
    ]
  end
  let :facts do
    {
      :osfamily               => 'Debian',
      :operatingsystem        => 'Ubuntu',
      :concat_basedir         => '/dne',
    }
  end
  context 'on Ubuntu 14.04' do
    let(:facts) { super().merge({ :operatingsystemrelease => '14.04' }) }
    it { is_expected.to contain_apache__mod('proxy_connect') }
  end
  context 'on Ubuntu 12.04' do
    let(:facts) { super().merge({ :operatingsystemrelease => '12.04' }) }
    it { is_expected.not_to contain_apache__mod('proxy_connect') }
  end
end
