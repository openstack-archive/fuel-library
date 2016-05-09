require 'spec_helper'

describe 'fuel::keystone', :type => :class do
  context 'on supported platform' do
    let(:facts) {{
      :osfamily               => 'Debian',
      :lsbdistid              => 'Ubuntu',
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '14.04',
    }}
    context 'with default parameters' do
      describe 'declares keystone class' do
        it { should contain_class('keystone').with(
          :enable_bootstrap    => false,
          :catalog_type        => 'sql',
          :token_expiration    => 86400,
          :token_provider      => 'keystone.token.providers.uuid.Provider',
          :admin_workers       => 5,
          :public_workers      => 5,
        )}
      end
    end
  end
end
