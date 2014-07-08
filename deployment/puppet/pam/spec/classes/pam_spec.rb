
require 'spec_helper'
 
describe 'pam' do

  oses = {

    'Debian' => {
      :operatingsystem        => 'Debian',
      :osfamily               => 'Debian',
      :operatingsystemrelease => '7.0',
      :lsbdistid              => 'Debian',
      :lsbdistrelease         => '7.0',
      :prefix_pamd            => '/etc/pam.d',
    },

    'Redhat' => {
      :operatingsystem        => 'Redhat',
      :osfamily               => 'Redhat',
      :operatingsystemrelease => '5.0',
      :lsbdistid              => 'Redhat',
      :lsbdistrelease         => '5.0',
      :prefix_pamd            => '/etc/pam.d',
    }

  }
  
  oses.keys.each do |os|
  
    let(:facts) { { 
      :operatingsystem        => oses[os][:operatingsystem],
      :operatingsystemrelease => oses[os][:operatingsystemrelease],
    } }
  
    describe "Running on #{os} Release #{oses[os][:operatingsystemrelease]}" do
      it { should include_class('pam::params')  }
      it { should contain_file(oses[os][:prefix_pamd]) }
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
