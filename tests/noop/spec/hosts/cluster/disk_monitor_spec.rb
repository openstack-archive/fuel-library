require 'spec_helper'
require 'shared-examples'
manifest = 'cluster/disk_monitor.pp'

describe manifest do
  shared_examples 'catalog' do
    let(:primary_controller) do
      Noop.hiera 'primary_controller'
    end

    let(:disks) do
      Noop.hiera 'corosync_disk_monitor', ['/var/log', '/var/lib/glance', '/var/libmysql']
    end

    let(:min_disk_free) do
      Noop.hiera 'corosync_min_disk_space', '100M'
    end

    let(:disk_unit) do
      Noop.hiera 'corosync_disk_unit', 'M'
    end

    let(:monitor_interval) do
      Noop.hiera 'monitor_interval', '15s'
    end

    it {
      should contain_class('cluster::sysinfo').with(
        :primary_controller => primary_controller,
        :disks              => disks,
        :min_disk_free      => min_disk_free,
        :disk_unit          => disk_unit,
        :monitor_interval   => monitor_interval
      )
    }

  end
  test_ubuntu_and_centos manifest
end

