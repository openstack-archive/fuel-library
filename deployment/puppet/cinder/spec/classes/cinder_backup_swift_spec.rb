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
# Unit tests for cinder::backup::swift class
#

require 'spec_helper'

describe 'cinder::backup::swift' do

  let :default_params do
    { :backup_swift_url             => 'http://localhost:8080/v1/AUTH_',
      :backup_swift_container       => 'volumes_backup',
      :backup_swift_object_size     => '52428800',
      :backup_swift_retry_attempts  => '3',
      :backup_swift_retry_backoff   => '2',
      :backup_compression_algorithm => 'zlib' }
  end

  let :params do
    {}
  end

  shared_examples_for 'cinder backup with swift' do
    let :p do
      default_params.merge(params)
    end

    it 'configures cinder.conf' do
      is_expected.to contain_cinder_config('DEFAULT/backup_driver').with_value('cinder.backup.drivers.swift')
      is_expected.to contain_cinder_config('DEFAULT/backup_swift_url').with_value(p[:backup_swift_url])
      is_expected.to contain_cinder_config('DEFAULT/backup_swift_container').with_value(p[:backup_swift_container])
      is_expected.to contain_cinder_config('DEFAULT/backup_swift_object_size').with_value(p[:backup_swift_object_size])
      is_expected.to contain_cinder_config('DEFAULT/backup_swift_retry_attempts').with_value(p[:backup_swift_retry_attempts])
      is_expected.to contain_cinder_config('DEFAULT/backup_swift_retry_backoff').with_value(p[:backup_swift_retry_backoff])
      is_expected.to contain_cinder_config('DEFAULT/backup_compression_algorithm').with_value(p[:backup_compression_algorithm])
    end

    context 'when overriding default parameters' do
      before :each do
        params.merge!(:backup_swift_url => 'https://controller2:8080/v1/AUTH_')
        params.merge!(:backup_swift_container => 'toto')
        params.merge!(:backup_swift_object_size => '123')
        params.merge!(:backup_swift_retry_attempts => '99')
        params.merge!(:backup_swift_retry_backoff => '56')
        params.merge!(:backup_compression_algorithm => 'None')
      end
      it 'should replace default parameters with new values' do
        is_expected.to contain_cinder_config('DEFAULT/backup_swift_url').with_value(p[:backup_swift_url])
        is_expected.to contain_cinder_config('DEFAULT/backup_swift_container').with_value(p[:backup_swift_container])
        is_expected.to contain_cinder_config('DEFAULT/backup_swift_object_size').with_value(p[:backup_swift_object_size])
        is_expected.to contain_cinder_config('DEFAULT/backup_swift_retry_attempts').with_value(p[:backup_swift_retry_attempts])
        is_expected.to contain_cinder_config('DEFAULT/backup_swift_retry_backoff').with_value(p[:backup_swift_retry_backoff])
        is_expected.to contain_cinder_config('DEFAULT/backup_compression_algorithm').with_value(p[:backup_compression_algorithm])
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'cinder backup with swift'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'cinder backup with swift'
  end

end
