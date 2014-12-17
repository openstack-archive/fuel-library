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
        'type': {'enum': ['puppet', 'shell', 'role', 'stage'],
                 'type': 'string'},
        'parameters': {'type': 'object'},
        'required_for': {'type': 'array'},
        'requires': {'type': 'array'}}}


TASKS_SCHEMA = {
    '$schema': 'http://json-schema.org/draft-04/schema#',
    'type': 'array',
    'items': TASK_SCHEMA}


@pytest.fixture
def tasks(request):
    tasks = []
    for file_name in request.config.getoption('tasks'):
        with open(file_name) as f:
            tasks.extend(yaml.load(f.read()))
    return tasks


def test_schema(tasks):
    checker = jsonschema.FormatChecker()
    jsonschema.validate(tasks, TASKS_SCHEMA, format_checker=checker)


def test_for_cycles_in_graph(tasks):
    graph = nx.DiGraph()
    for task in tasks:
        graph.add_node(task['id'])
        if 'required_for' in task:
            for req in task['required_for']:
                graph.add_edge(task['id'], req)
        if 'requires' in task:
            for req in task['requires']:
                graph.add_edge(req, task['id'])
        if 'role' in task:
            for req in task['role']:
                graph.add_edge(task['id'], req)
        if 'stage' in task:
            graph.add_edge(task['id'], task['stage'])
    #todo(dshulyak) show where cycle is
    dag = nx.is_directed_acyclic_graph(graph)
    assert dag, 'Graph is not acyclic.'
