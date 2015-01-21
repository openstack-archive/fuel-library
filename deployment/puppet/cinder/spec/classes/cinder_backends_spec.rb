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
# Unit tests for cinder::backends class
#

require 'spec_helper'

describe 'cinder::backends' do

  let :default_params do
    {}
  end

  let :params do
    {}
  end

  shared_examples_for 'cinder backends' do

    let :p do
      default_params.merge(params)
    end

    context 'configure cinder with default parameters' do
      before :each do
        params.merge!(
         :enabled_backends => ['lowcost', 'regular', 'premium'],
         :default_volume_type => false
        )
      end

      it 'configures cinder.conf with default params' do
        should contain_cinder_config('DEFAULT/enabled_backends').with_value(p[:enabled_backends].join(','))
      end
    end

    context 'configure cinder with a default volume type' do
      before :each do
        params.merge!(
         :enabled_backends    => ['foo', 'bar'],
         :default_volume_type => 'regular'
        )
      end

      it 'should fail to configure default volume type' do
        expect { subject }.to raise_error(Puppet::Error, /The default_volume_type parameter is deprecated in this class, you should declare it in cinder::api./)
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'cinder backends'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'cinder backends'
  end

end
