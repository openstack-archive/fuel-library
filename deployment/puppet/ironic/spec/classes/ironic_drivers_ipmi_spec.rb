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
# Unit tests for ironic::drivers::ipmi class
#

require 'spec_helper'

describe 'ironic::drivers::ipmi' do

  let :default_params do
    { :retry_timeout => '10' }
  end

  let :params do
    {}
  end

  shared_examples_for 'ironic ipmi driver' do
    let :p do
      default_params.merge(params)
    end

    it 'configures ironic.conf' do
      is_expected.to contain_ironic_config('ipmi/retry_timeout').with_value(p[:retry_timeout])
    end

    context 'when overriding parameters' do
      before do
        params.merge!(:retry_timeout => '50')
      end
      it 'should replace default parameter with new value' do
        is_expected.to contain_ironic_config('ipmi/retry_timeout').with_value(p[:retry_timeout])
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'ironic ipmi driver'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'ironic ipmi driver'
  end

end
