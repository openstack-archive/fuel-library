require 'spec_helper'

describe 'vmware::ceilometer' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      it { is_expected.to compile.with_all_deps }

      xit 'should enable ceilometer-polling' do
        should contain_service('ceilometer-polling').with({
                                                              'enabled' => 'true'
                                                          })
      end

    end
  end
end
