require 'spec_helper'

describe 'nova::scheduler::filter' do

  it { should contain_nova_config('DEFAULT/scheduler_host_manager').with_value('nova.scheduler.host_manager.HostManager') }
  it { should contain_nova_config('DEFAULT/scheduler_max_attempts').with_value('3') }
  it { should contain_nova_config('DEFAULT/scheduler_host_subset_size').with_value('1') }
  it { should contain_nova_config('DEFAULT/cpu_allocation_ratio').with_value('16.0') }
  it { should contain_nova_config('DEFAULT/disk_allocation_ratio').with_value('1.0') }
  it { should contain_nova_config('DEFAULT/max_io_ops_per_host').with_value('8') }
  it { should contain_nova_config('DEFAULT/max_instances_per_host').with_value('50') }
  it { should contain_nova_config('DEFAULT/ram_allocation_ratio').with_value('1.5') }
  it { should contain_nova_config('DEFAULT/scheduler_available_filters').with_value('nova.scheduler.filters.all_filters') }
  it { should contain_nova_config('DEFAULT/scheduler_weight_classes').with_value('nova.scheduler.weights.all_weighers') }

  describe 'when overriding params' do

    let :params do
      {:scheduler_max_attempts     => '4',
       :isolated_images            => ['ubuntu1','centos2'],
       :isolated_hosts             => ['192.168.1.2','192.168.1.3'],
       :scheduler_default_filters  => ['RetryFilter','AvailabilityZoneFilter','RamFilter']
      }
    end

  it { should contain_nova_config('DEFAULT/scheduler_max_attempts').with_value('4') }
  it { should contain_nova_config('DEFAULT/isolated_images').with_value('ubuntu1,centos2') }
  it { should contain_nova_config('DEFAULT/isolated_hosts').with_value('192.168.1.2,192.168.1.3') }
  it { should contain_nova_config('DEFAULT/scheduler_default_filters').with_value('RetryFilter,AvailabilityZoneFilter,RamFilter') }

  end

end
