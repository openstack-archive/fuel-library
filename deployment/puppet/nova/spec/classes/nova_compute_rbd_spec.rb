#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for nova::compute::rbd class
#

require 'spec_helper'

describe 'nova::compute::rbd' do

  let :params do
    { :libvirt_rbd_user             => 'nova',
      :libvirt_rbd_secret_uuid      => false,
      :libvirt_images_rbd_pool      => 'rbd',
      :libvirt_images_rbd_ceph_conf => '/etc/ceph/ceph.conf' }
  end

  shared_examples_for 'nova compute rbd' do

    it { should contain_class('nova::params') }

    it 'configure nova.conf with default parameters' do
        should contain_nova_config('libvirt/images_type').with_value('rbd')
        should contain_nova_config('libvirt/images_rbd_pool').with_value('rbd')
        should contain_nova_config('libvirt/images_rbd_ceph_conf').with_value('/etc/ceph/ceph.conf')
        should contain_nova_config('libvirt/rbd_user').with_value('nova')
    end

    context 'when overriding default parameters' do
      before :each do
        params.merge!(
          :libvirt_rbd_user             => 'joe',
          :libvirt_rbd_secret_uuid      => false,
          :libvirt_images_rbd_pool      => 'AnotherPool',
          :libvirt_images_rbd_ceph_conf => '/tmp/ceph.conf'
        )
      end

      it 'configure nova.conf with overriden parameters' do
          should contain_nova_config('libvirt/images_type').with_value('rbd')
          should contain_nova_config('libvirt/images_rbd_pool').with_value('AnotherPool')
          should contain_nova_config('libvirt/images_rbd_ceph_conf').with_value('/tmp/ceph.conf')
          should contain_nova_config('libvirt/rbd_user').with_value('joe')
      end
    end

    context 'when using cephx' do
      before :each do
        params.merge!(
          :libvirt_rbd_secret_uuid => 'UUID'
        )
      end

      it 'configure nova.conf with RBD secret UUID' do
          should contain_nova_config('libvirt/rbd_secret_uuid').with_value('UUID')
      end

      it 'configure ceph on compute nodes' do
        verify_contents(subject, '/etc/nova/secret.xml', [
          "<secret ephemeral=\'no\' private=\'no\'>",
          "  <usage type=\'ceph\'>",
          "    <name>client.nova secret</name>",
          "  </usage>",
          "  <uuid>UUID</uuid>",
          "</secret>"
        ])
        should contain_exec('get-or-set virsh secret').with(
          :command =>  '/usr/bin/virsh secret-define --file /etc/nova/secret.xml | /usr/bin/awk \'{print $2}\' | sed \'/^$/d\' > /etc/nova/virsh.secret',
          :creates => '/etc/nova/virsh.secret',
          :require => 'File[/etc/nova/secret.xml]'
        )
        should contain_exec('set-secret-value virsh').with(
          :command => "/usr/bin/virsh secret-set-value --secret $(cat /etc/nova/virsh.secret) --base64 $(ceph auth get-key client.nova)"
        )
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'nova compute rbd'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'nova compute rbd'
  end

end
