require 'spec_helper'

describe 'nova::quota' do

  it { should contain_nova_config('DEFAULT/quota_ram').with_value('51200') }

  describe 'when overriding params' do

    let :params do
      {:quota_ram => '1'}
    end

    it { should contain_nova_config('DEFAULT/quota_ram').with_value('1') }

  end

end
