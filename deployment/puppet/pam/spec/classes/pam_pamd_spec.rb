
require 'spec_helper'
 
describe 'pam::pamd' do

  oses = {

    'Debian' => {
      :operatingsystem        => 'Debian',
      :osfamily               => 'Debian',
      :operatingsystemrelease => '7.0',
      :lsbdistid              => 'Debian',
      :lsbdistrelease         => '7.0',
      :prefix_pamd            => '/etc/pam.d',
      :pamd_class             => 'pam::pamd::debian',
    },

    'Redhat' => {
      :operatingsystem        => 'Redhat',
      :osfamily               => 'Redhat',
      :operatingsystemrelease => '5.0',
      :lsbdistid              => 'Redhat',
      :lsbdistrelease         => '5.0',
      :prefix_pamd            => '/etc/pam.d',
      :pamd_class             => 'pam::pamd::redhat',
    },

    'CentOS' => {
      :operatingsystem        => 'CentOS',
      :osfamily               => 'Redhat',
      :operatingsystemrelease => '5.0',
      :lsbdistid              => 'CentOS',
      :lsbdistrelease         => '5.0',
      :prefix_pamd            => '/etc/pam.d',
      :pamd_class             => 'pam::pamd::redhat',
    },

  }
  
  oses.keys.each do |os|
  
    describe "Running on #{os} Release #{oses[os][:operatingsystemrelease]}" do

      let(:facts) { { 
        :operatingsystem        => oses[os][:operatingsystem],
        :operatingsystemrelease => oses[os][:operatingsystemrelease],
      } }
  
      it { should include_class('pam::params')  }

      context "pam_ldap enabled" do
        let(:params) { { 
          :pam_ldap  => true,
        } } 
        it { should include_class(oses[os][:pamd_class]) }
      end

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
