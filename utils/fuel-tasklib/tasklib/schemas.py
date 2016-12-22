#    Copyright 2015 Mirantis, Inc.
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


class BaseTasksSchema(object):

    base_task_schema = {
        '$schema': 'http://json-schema.org/draft-04/schema#',
        'type': 'object',
        'required': ['type', 'id'],
        'properties': {
            'id': {'type': 'string',
                   'minLength': 1},
            'type': {'enum': [],
                     'type': 'string'},
            'parameters': {'type': 'object'},
            'required_for': {'type': 'array'},
            'requires': {'type': 'array'},
        }}

    base_tasks_schema = {
        '$schema': 'http://json-schema.org/draft-04/schema#',
        'type': 'array',
        'items': ''}

    types = {'enum': ['puppet', 'shell'],
             'type': 'string'},

    @property
    def task_schema(self):
        self.base_task_schema['properties']['type'] = self.types
        return self.base_task_schema

    @property
    def tasks_schema(self):
        self.base_tasks_schema['items'] = self.task_schema
        return self.base_tasks_schema


class TasksSchema61(BaseTasksSchema):

    types = {'enum': ['puppet', 'shell', 'group', 'stage', 'copy_files',
                      'sync', 'upload_file'],
             'type': 'string'}


class TasksSchema70(BaseTasksSchema):

    types = {'enum': ['puppet', 'shell', 'sync', 'upload_file', 'group',
                      'stage', 'skipped', 'reboot',  'copy_files'],
             'type': 'string'}


VERSIONS_SCHEMAS_MAP = {
    "6.1": TasksSchema61,
    "7.0": TasksSchema70,
    "8.0": TasksSchema70,
    "last": TasksSchema70,
}
