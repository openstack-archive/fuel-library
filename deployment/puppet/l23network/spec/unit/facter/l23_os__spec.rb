require 'spec_helper'

describe 'l23_os', :type => :fact do

  before { Facter.clear }

  subject do
    Facter.fact(:l23_os)
  end

  context 'Ubuntu 14.04' do
    before :each do
      puppet_debug_override()
      Facter.fact(:operatingsystem).stubs(:value).returns('Ubuntu')
      Facter.fact(:operatingsystemmajrelease).stubs(:value).returns('14.04')
    end

    it { expect(subject.value).to eq('ubuntu14')}
  end

  context 'Ubuntu 15.xx' do
    before :each do
      puppet_debug_override()
      Facter.fact(:operatingsystem).stubs(:value).returns('Ubuntu')
      Facter.fact(:operatingsystemmajrelease).stubs(:value).returns('15.10')
    end

    # the same way as ubuntu14
    it { expect(subject.value).to eq('ubuntu14')}
  end

  context 'Ubuntu 16.04' do
    before :each do
      puppet_debug_override()
      Facter.fact(:operatingsystem).stubs(:value).returns('Ubuntu')
      Facter.fact(:operatingsystemmajrelease).stubs(:value).returns('16.04')
    end

    it { expect(subject.value).to eq('ubuntu16')}
  end

  context 'Centos-6' do
    before :each do
      puppet_debug_override()
      Facter.fact(:operatingsystem).stubs(:value).returns('CentOS')
      Facter.fact(:operatingsystemmajrelease).stubs(:value).returns('6')
    end

    it { expect(subject.value).to eq('centos6')}
  end

  context 'Centos-7' do
    before :each do
      puppet_debug_override()
      Facter.fact(:operatingsystem).stubs(:value).returns('CentOS')
      Facter.fact(:operatingsystemmajrelease).stubs(:value).returns('7')
    end

    it { expect(subject.value).to eq('centos7')}
  end

  context 'RedHat-7' do
    before :each do
      puppet_debug_override()
      Facter.fact(:operatingsystem).stubs(:value).returns('RedHat')
      Facter.fact(:operatingsystemmajrelease).stubs(:value).returns('7')
    end

    it { expect(subject.value).to eq('redhat7')}
  end

  context 'OracleLinux-7' do
    before :each do
      puppet_debug_override()
      Facter.fact(:operatingsystem).stubs(:value).returns('OracleLinux')
      Facter.fact(:operatingsystemmajrelease).stubs(:value).returns('7')
    end

    it { expect(subject.value).to eq('oraclelinux7')}
  end

end
