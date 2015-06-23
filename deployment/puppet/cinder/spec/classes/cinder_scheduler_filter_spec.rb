require 'spec_helper'

describe 'cinder::scheduler::filter' do

  describe 'when overriding params' do

    let :params do
      {
       :scheduler_default_filters => ['AvailabilityZoneFilter', 'CapacityFilter', 'CapabilitiesFilter']
      }
    end

    it { is_expected.to contain_cinder_config('DEFAULT/scheduler_default_filters').with_value('AvailabilityZoneFilter,CapacityFilter,CapabilitiesFilter') }

  end

end
