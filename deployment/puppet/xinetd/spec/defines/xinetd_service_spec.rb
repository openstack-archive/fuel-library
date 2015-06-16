require 'spec_helper'

describe 'xinetd::service' do

  let :facts do
    { :osfamily => 'Debian' }
  end

  let :default_params do
    {
      'port'   => '80',
      'server' => 'httpd'
    }
  end

  let :title do
    "httpd"
  end

  describe 'with default ensure' do
    let :params do
      default_params
    end
    it {
      should contain_file('/etc/xinetd.d/httpd').with_ensure('present')
    }
  end

  describe 'with ensure=present' do
    let :params do
      default_params.merge({'ensure' => 'present'})
    end
    it {
      should contain_file('/etc/xinetd.d/httpd').with_ensure('present')
    }
  end

  describe 'with ensure=absent' do
    let :params do
      default_params.merge({'ensure' => 'absent'})
    end
    it {
      should contain_file('/etc/xinetd.d/httpd').with_ensure('absent')
    }
  end

  describe 'without log_on_<success|failure>' do
    let :params do
      default_params
    end
    it {
      should contain_file('/etc/xinetd.d/httpd').without_content(/log_on_success/)
      should contain_file('/etc/xinetd.d/httpd').without_content(/log_on_failure/)
    }
  end

  describe 'with log_on_<success|failure> w/default operator' do
    let :params do
      default_params.merge({
        :log_on_success => 'SUCCESS_TEST',
        :log_on_failure => 'FAILURE_TEST',
      })
    end
    it {
      should contain_file('/etc/xinetd.d/httpd').with_content(
        /log_on_success\s*\+=\s*SUCCESS_TEST/)
      should contain_file('/etc/xinetd.d/httpd').with_content(
        /log_on_failure\s*\+=\s*FAILURE_TEST/)
    }
  end

  describe 'with log_on_<success|failure> with equal operator' do
    let :params do
      default_params.merge({
        :log_on_success => 'SUCCESS_TEST',
        :log_on_failure => 'FAILURE_TEST',
        :log_on_success_operator => '=',
        :log_on_failure_operator => '=',
      })
    end
    it {
      should contain_file('/etc/xinetd.d/httpd').with_content(
        /log_on_success\s*\=\s*SUCCESS_TEST/)
      should contain_file('/etc/xinetd.d/httpd').with_content(
        /log_on_failure\s*\=\s*FAILURE_TEST/)
    }
  end

  # nice values, good
  ['-19','9','19'].each do |i|
    describe "with nice #{i}" do
      let :params do
        default_params.merge({ :nice => i })
      end
      it {
        should contain_file('/etc/xinetd.d/httpd').with_content(
          /nice\s*=\s*#{i}/)
      }
    end
  end
  # nice values, bad
  ['-20','90','foo'].each do |i|
    describe "with nice #{i}" do
      let :params do
        default_params.merge({ :nice => i })
      end
      it { expect { should compile }.to raise_error(Puppet::Error) }
    end
  end
end
