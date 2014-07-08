
require 'spec_helper'

oses = @oses

describe 'pam::pamd::redhat' do

  oses.keys.each do |os|
 
    next if oses[os][:osfamily] != 'Redhat'

    describe "Running on #{os} Release #{oses[os][:operatingsystemmajrelease]}" do

      let(:facts) { { 
        :osfamily                  => oses[os][:osfamily],
        :operatingsystem           => oses[os][:operatingsystem],
        :operatingsystemmajrelease => oses[os][:operatingsystemmajrelease],
        :architecture              => oses[os][:architecture],
      } }
   
      context 'Simple usage' do
        it { should include_class('pam::params')  }
        it { should contain_file(oses[os][:cfg_system_auth]) }
        it { should contain_file(oses[os][:cfg_system_auth_ac]) }
      end

      #context "With pam_ldap enabled" do
      #
      #  it { should contain_file('/etc/ldap.conf') }
      #  if oses[os][:operatingsystemmajrelease] == '6'
      #    it { should contain_file(oses[os][:cfg_password_auth_ac]).with( {
      #          :ensure => 'link',
      #          :target => oses[os][:cfg_system_auth]
      #        } ) 
      #    }
      #    it { should contain_file('/etc/pam_ldap.conf') }
      #  end
      #end

    end

  end

	describe 'Running on unsupported OS' do
		let(:facts) { {
			:operatingsystem => 'solaris'
		} }
		it do
			expect {
				should include_class('pam::params')
			}.to raise_error(Puppet::Error, /^Operating system.*/)
		end
	end
	
end
