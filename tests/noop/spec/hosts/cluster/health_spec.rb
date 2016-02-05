require 'spec_helper'
require 'shared-examples'
manifest = 'cluster/health.pp'

describe manifest do
  shared_examples 'catalog' do
    let(:facts) {
      task.facts_data.merge({
        :mounts => '/,/boot,/var/log,/var/lib/glance,/var/lib/mysql,/var/lib/horizon'
      })
    }

    let(:disks) do
      task.hiera 'corosync_disk_monitor', ['/', '/var/log', '/var/lib/glance', '/var/lib/mysql']
    end

    let(:min_disk_free) do
      task.hiera 'corosync_min_disk_space', '512M'
    end

    let(:disk_unit) do
      task.hiera 'corosync_disk_unit', 'M'
    end

    let(:monitor_interval) do
      task.hiera 'corosync_monitor_interval', '15s'
    end

    it {
      should contain_class('cluster::sysinfo').with(
        :disks              => disks,
        :min_disk_free      => min_disk_free,
        :disk_unit          => disk_unit,
        :monitor_interval   => monitor_interval
      )
    }

  end
  test_ubuntu_and_centos manifest
end

