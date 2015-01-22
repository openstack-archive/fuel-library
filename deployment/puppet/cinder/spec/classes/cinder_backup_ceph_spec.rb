#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
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
# Unit tests for cinder::ceph class
#

require 'spec_helper'

describe 'cinder::backup::ceph' do

  let :default_params do
    { :backup_ceph_conf         => '/etc/ceph/ceph.conf',
      :backup_ceph_user         => 'cinder',
      :backup_ceph_chunk_size   => '134217728',
      :backup_ceph_pool         => 'backups',
      :backup_ceph_stripe_unit  => '0',
      :backup_ceph_stripe_count => '0' }
  end

  let :params do
    {}
  end

  shared_examples_for 'cinder backup with ceph' do
    let :p do
      default_params.merge(params)
    end

    it 'configures cinder.conf' do
      should contain_cinder_config('DEFAULT/backup_driver').with_value('cinder.backup.drivers.ceph')
      should contain_cinder_config('DEFAULT/backup_ceph_conf').with_value(p[:backup_ceph_conf])
      should contain_cinder_config('DEFAULT/backup_ceph_user').with_value(p[:backup_ceph_user])
      should contain_cinder_config('DEFAULT/backup_ceph_chunk_size').with_value(p[:backup_ceph_chunk_size])
      should contain_cinder_config('DEFAULT/backup_ceph_pool').with_value(p[:backup_ceph_pool])
      should contain_cinder_config('DEFAULT/backup_ceph_stripe_unit').with_value(p[:backup_ceph_stripe_unit])
      should contain_cinder_config('DEFAULT/backup_ceph_stripe_count').with_value(p[:backup_ceph_stripe_count])
    end

    context 'when overriding default parameters' do
      before :each do
        params.merge!(:backup_ceph_conf => '/tmp/ceph.conf')
        params.merge!(:backup_ceph_user => 'toto')
        params.merge!(:backup_ceph_chunk_size => '123')
        params.merge!(:backup_ceph_pool => 'foo')
        params.merge!(:backup_ceph_stripe_unit => '56')
        params.merge!(:backup_ceph_stripe_count => '67')
      end
      it 'should replace default parameters with new values' do
        should contain_cinder_config('DEFAULT/backup_ceph_conf').with_value(p[:backup_ceph_conf])
        should contain_cinder_config('DEFAULT/backup_ceph_user').with_value(p[:backup_ceph_user])
        should contain_cinder_config('DEFAULT/backup_ceph_chunk_size').with_value(p[:backup_ceph_chunk_size])
        should contain_cinder_config('DEFAULT/backup_ceph_pool').with_value(p[:backup_ceph_pool])
        should contain_cinder_config('DEFAULT/backup_ceph_stripe_unit').with_value(p[:backup_ceph_stripe_unit])
        should contain_cinder_config('DEFAULT/backup_ceph_stripe_count').with_value(p[:backup_ceph_stripe_count])
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'cinder backup with ceph'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'cinder backup with ceph'
  end

end
