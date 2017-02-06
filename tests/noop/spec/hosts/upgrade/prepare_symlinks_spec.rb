# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: mongo
# ROLE: ironic
# ROLE: controller
# ROLE: compute
# ROLE: cinder-block-device
# ROLE: cinder
# ROLE: ceph-osd
require 'spec_helper'
require 'shared-examples'

manifest = 'upgrade/prepare_symlinks.pp'

describe manifest do

  shared_examples 'catalog' do
    # TODO degorenko : update noop fixtures with mu_upgrade hash
    mu_upgrade = Noop.hiera('mu_upgrade', {})
    context 'it should create all symlinks', :if => mu_upgrade['enabled'] do
      [ '/etc/fuel/', '/etc/fuel/maintenance/', '/etc/fuel/maintenance/apt/' ].each do |dir|
        it { is_expected.to contain_file(dir).with(:ensure => 'directory') }
      end
      it { is_expected.to contain_file('/etc/fuel/maintenance/apt/sources.list.d/').with(
             :ensure => 'directory',
             :recurse => true,
             :purge   => true )}
      it { is_expected.to contain_osnailyfacter__upgrade__repo_symlink('mos-updates') }
      it { is_expected.to contain_file('symlink_repo-mos-updates').with(
             :ensure => 'link',
             :path   => "/etc/fuel/maintenance/apt/sources.list.d/mos-updates.list",
             :target => "/etc/apt/sources.list.d/mos-updates.list",
           ) }
    end
  end
  test_ubuntu_and_centos manifest
end
