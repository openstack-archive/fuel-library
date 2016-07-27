require 'spec_helper'

describe 'fuel::keystone', :type => :class do
  context 'on supported platform' do
    let(:facts) {{
      :osfamily               => 'RedHat',
      :lsbdistid              => 'CentOS',
      :operatingsystem        => 'CentOS',
      :operatingsystemrelease => '7.2',
      :processorcount         => 48,
    }}
    context 'with default parameters' do
      describe 'limits keystone workers' do
        it {
          should contain_class('keystone').with(
            :public_workers => 16,
            :admin_workers  => 16
          )
        }
      end
    end
  end
end
