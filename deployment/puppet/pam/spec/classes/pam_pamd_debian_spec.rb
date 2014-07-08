
require 'spec_helper'
 
oses = @oses

describe 'pam::pamd::debian' do

  oses.keys.each do |os|
  
    next if oses[os][:osfamily] != 'Debian'
 
    describe "Running on #{os} Release #{oses[os][:operatingsystemmajrelease]}" do

      let(:facts) { { 
        :osfamily                  => oses[os][:osfamily],
        :operatingsystem           => oses[os][:operatingsystem],
        :operatingsystemmajrelease => oses[os][:operatingsystemmajrelease],
        :architecture              => oses[os][:architecture],
      } }
 
      it { should include_class('pam::params')  }

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
