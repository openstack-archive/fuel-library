#!/usr/bin/python
#    Copyright 2014 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import sys
import yaml

astuteyaml = sys.argv[1]
data = yaml.load(open(astuteyaml))


def traverse(data, head=''):
    if isinstance(data, dict):
        for key, value in data.iteritems():
            new_head = "{head}_{tail}".format(head=head, tail=key).lstrip('_')
            traverse(value, new_head)
    elif isinstance(data, (unicode, str)):
        if "'" in data:
            print("#Skipped because value contains single quote")
            print("#{head}='{value}'".format(head=head, value=data))
        print("{head}='{value}'".format(head=head, value=data))
    elif isinstance(data, list):
        for i, item in enumerate(data):
            new_head = "{head}_{tail}".format(head=head, tail=i).lstrip('_')
            traverse(item, new_head)

traverse(data)
