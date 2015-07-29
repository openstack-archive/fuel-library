require 'spec_helper'

describe 'nova::manage::network' do

  let :facts do
    {:osfamily => 'RedHat'}
  end

  let :pre_condition do
    'include nova'
  end

  let :title do
    'foo'
  end

  describe 'with only required parameters' do
    let :params do
      {
        :network => '10.0.0.0/24'
      }
    end
    it { is_expected.to contain_nova_network('foo').with(
      :ensure        => 'present',
      :network       => '10.0.0.0/24',
      :label         => 'novanetwork',
      :num_networks  => 1,
      :project       => nil,
      :allowed_start => nil,
      :allowed_end   => nil,
    ) }
  end
  describe 'when overriding num networks' do
    let :params do
      {
        :network      => '10.0.0.0/20',
        :num_networks => 2
      }
    end
    it { is_expected.to contain_nova_network('foo').with(
      :network      => '10.0.0.0/20',
      :num_networks => 2
    ) }
  end

  describe 'when overriding projects' do
    let :params do
      {
        :network => '10.0.0.0/20',
        :project => 'foo'
      }
    end
    it { is_expected.to contain_nova_network('foo').with(
      :network => '10.0.0.0/20',
      :project => 'foo'
    ) }
  end

  describe 'when overriding allowed range' do
    let :params do
      {
        :network       => '10.0.0.0/20',
        :allowed_start => '10.0.0.1',
        :allowed_end   => '10.0.0.5'
      }
    end
    it { is_expected.to contain_nova_network('foo').with(
      :network       => '10.0.0.0/20',
      :allowed_start => '10.0.0.1',
      :allowed_end   => '10.0.0.5'
    ) }
  end

end
