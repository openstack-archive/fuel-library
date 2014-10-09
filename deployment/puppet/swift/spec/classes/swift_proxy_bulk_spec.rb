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
# Tests for swift::proxy::bulk
#

require 'spec_helper'

describe 'swift::proxy::bulk' do

  let :facts do
    {
      :concat_basedir => '/var/lib/puppet/concat'
    }
  end

  let :pre_condition do
    'class { "concat::setup": }
    concat { "/etc/swift/proxy-server.conf": }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/21_swift_bulk"
  end

  describe "when using default parameters" do
    it 'should build the fragment with correct parameters' do
      verify_contents(subject, fragment_file,
        [
          '[filter:bulk]',
          'use = egg:swift#bulk',
          'max_containers_per_extraction = 10000',
          'max_failed_extractions = 1000',
          'max_deletes_per_request = 10000',
          'yield_frequency = 60',
        ]
      )
    end
  end

  describe "when overriding default parameters" do
    let :params do
      {
        :max_containers_per_extraction => 5000,
        :max_failed_extractions        => 500,
        :max_deletes_per_request       => 5000,
        :yield_frequency               => 10
      }
    end
    it 'should build the fragment with correct parameters' do
      verify_contents(subject, fragment_file,
        [
          '[filter:bulk]',
          'use = egg:swift#bulk',
          'max_containers_per_extraction = 5000',
          'max_failed_extractions = 500',
          'max_deletes_per_request = 5000',
          'yield_frequency = 10',
        ]
      )
    end
  end

end
