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
# Tests for swift::proxy::container_quotas
#

require 'spec_helper'

describe 'swift::proxy::container_quotas' do

  let :facts do
    {}
  end

  let :pre_condition do
    'class { "concat::setup": }
    concat { "/etc/swift/proxy-server.conf": }'
  end

  let :fragment_file do
    "/var/lib/puppet/concat/_etc_swift_proxy-server.conf/fragments/81_swift_container_quotas"
  end

  it { is_expected.to contain_file(fragment_file).with_content(/\[filter:container_quotas\]/) }
  it { is_expected.to contain_file(fragment_file).with_content(/use = egg:swift#container_quotas/) }

end
