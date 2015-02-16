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

import os

import jsonschema
import networkx as nx
import pytest
import yaml


TASK_SCHEMA = {
    '$schema': 'http://json-schema.org/draft-04/schema#',
    'type': 'object',
    'required': ['type', 'id'],
    'properties': {
        'id': {'type': 'string'},
        'type': {'enum': ['puppet', 'shell', 'group',
                          'stage', 'upload_file', 'sync'],
                 'type': 'string'},
        'parameters': {'type': 'object'},
        'required_for': {'type': 'array'},
        'requires': {'type': 'array'}}}


TASKS_SCHEMA = {
    '$schema': 'http://json-schema.org/draft-04/schema#',
    'type': 'array',
    'items': TASK_SCHEMA}


def get_files(base_dir, patterns=('*tasks.yaml',)):
    for root, dirs, files in os.walk(base_dir):
        for file_name in files:
            if file_name in patterns:
                yield os.path.join(root, file_name)


@pytest.fixture
def tasks(request):
    tasks = []
    for file_path in get_files(request.config.getoption('dir')):
        with open(file_path) as f:
            tasks.extend(yaml.load(f.read()))
    return tasks


@pytest.fixture
def graph(tasks):
    graph = nx.DiGraph()
    for task in tasks:
        graph.add_node(task['id'], **task)
        if 'required_for' in task:
            for req in task['required_for']:
                graph.add_edge(task['id'], req)
        if 'requires' in task:
            for req in task['requires']:
                graph.add_edge(req, task['id'])

        if 'groups' in task:
            for req in task['groups']:
                graph.add_edge(task['id'], req)
        if 'tasks' in task:
            for req in task['tasks']:
                graph.add_edge(req, task['id'])

        if 'stage' in task:
            graph.add_edge(task['id'], task['stage'])
    return graph


def test_schema(tasks):
    checker = jsonschema.FormatChecker()
    jsonschema.validate(tasks, TASKS_SCHEMA, format_checker=checker)


def test_for_cycles_in_graph(graph):
    #todo(dshulyak) show where cycle is
    dag = nx.is_directed_acyclic_graph(graph)
    assert dag, 'Graph is not acyclic.'


def test_not_empty(graph):
    for node_name, node in graph.node.items():
        assert node != {}, "{0} should not be an empty".format(node_name)

