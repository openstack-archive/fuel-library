#!/usr/bin/env python

# Copyright 2015 Mirantis, Inc.
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

# usage: task_graph.py [-h] [--workbook] [--clear_workbook] [--dot] [--png]
#                      [--png_file PNG_FILE] [--open] [--debug]
#                      [--filter FILTER] [--topology]
#                      PLACE [PLACE ...]
#
# positional arguments:
#   PLACE                 The list of files of directories wheretasks can be
#                         found
#
# optional arguments:
#   -h, --help            show this help message and exit
#   --workbook, -w        Output the raw workbook
#   --clear_workbook, -c  Output the clear workbook
#   --dot, -D             Output the graph in dot format
#   --png, -p             Write the graph in png format (default)
#   --png_file PNG_FILE, -P PNG_FILE
#                         Write graph image to this file
#   --open, -o            Open the image after creation
#   --debug, -d           Print debug messages
#   --filter FILTER, -f FILTER
#                         Filter tasks by this group or role
#   --topology, -t        Show the tasks topology(possible execution order)
#
# This tools can be used to create a task graph image. Just point it
# at the folder where tasks.yaml files can be found.
#
# > ./task_graph.py deployment/puppet/osnailyfacter/modular
#
# It will create task_graph.png file in the current directroy.
#
# You can also use -w and -c options to inspect the workbook yamls
# files and output graph as graphviz file with -o option.
#
# You can filter graph by roles and groups with -f option like this
# > ./task_graph.py -f controller deployment/puppet/osnailyfacter/modular
#
# And you can use -t option to view the possible order of task execution
# with the current graph.
#
# > ./task_graph.py -t deployment/puppet/osnailyfacter/modular

import fnmatch
import os
import re
import sys
import argparse
import yaml

try:
    import pygraphviz
except ImportError:
    pass

import networkx


class IO(object):
    @classmethod
    def debug(cls, msg):
        if not cls.args.debug:
            return
        if not msg.endswith("\n"):
            msg += "\n"
        sys.stdout.write(msg)

    @classmethod
    def output(cls, line, fill=None, newline=True):
        line = str(line)
        if fill:
            line = line[0:fill].ljust(fill)
        if newline and not line.endswith("\n"):
            line += "\n"
        sys.stdout.write(line)

    @classmethod
    def task_files(cls, directory, file_pattern='*tasks.yaml'):
        if os.path.isfile(directory):
            if fnmatch.fnmatch(directory, file_pattern):
                yield directory
        for root, dirs, files in os.walk(directory):
            for file_name in files:
                if fnmatch.fnmatch(file_name, file_pattern):
                    task_path = os.path.join(root, file_name)
                    if not os.path.isfile(task_path):
                        continue
                    yield task_path

    @classmethod
    def options(cls):
        parser = argparse.ArgumentParser()
        parser.add_argument("--workbook", "-w",
                            action="store_true",
                            default=False,
                            help='Output the raw workbook')
        parser.add_argument("--clear_workbook", "-c",
                            action="store_true",
                            default=False,
                            help='Output the clear workbook')
        parser.add_argument("--dot", "-D",
                            action="store_true",
                            default=False,
                            help='Output the graph in dot format')
        parser.add_argument("--png", "-p",
                            action="store_true",
                            default=True,
                            help='Write the graph in png format (default)')
        parser.add_argument("--png_file", "-P",
                            type=str,
                            default='task_graph.png',
                            help='Write graph image to this file')
        parser.add_argument("--open", "-o",
                            action="store_true",
                            default=False,
                            help='Open the image after creation')
        parser.add_argument("--debug", "-d",
                            action="store_true",
                            default=False,
                            help='Print debug messages')
        parser.add_argument("--filter", "-f",
                            help="Filter tasks by this group or role",
                            default=None)
        parser.add_argument("--topology", "-t",
                            action="store_true",
                            help="Show the tasks topology"
                                 "(possible execution order)",
                            default=False)
        parser.add_argument('places',
                            metavar='PLACE',
                            type=str,
                            nargs='+',
                            help='The list of files of directories where'
                                 'tasks can be found',
                            default=[])

        cls.args = parser.parse_args()
        return cls.args

    @classmethod
    def view_image(cls, img_file):
        if not os.path.isfile(img_file):
            return
        if sys.platform.startswith('linux'):
            os.system('xdg-open "%s"' % img_file)
        elif sys.platform.startswith('darwin'):
            os.system('open "%s"' % img_file)

    @classmethod
    def main(cls):
        cls.options()
        task_graph = TaskGraph()

        for place in cls.args.places:
            for task_file in cls.task_files(place):
                task_graph.load_yaml_file(task_file)

        if cls.args.workbook:
            IO.output(yaml.dump(task_graph.workbook))
            return

        task_graph.process_data()
        task_graph.resolve_cross_links()
        task_graph.filter_processed_data(filter=cls.args.filter)

        if cls.args.clear_workbook:
            IO.output(yaml.dump(task_graph.data))
            return

        task_graph.build_graph()

        if cls.args.topology:
            task_graph.show_topology()
            return

        if cls.args.png:
            task_graph.create_image(cls.args.png_file)
            if cls.args.open:
                cls.view_image(cls.args.png_file)


class TaskGraph(object):
    def __init__(self):
        self.data = {}
        self.workbook = []
        self.graph = networkx.DiGraph()
        self._max_task_id_length = None

        self.options = {
            'debug': False,
            'prog': 'dot',
            'default_node': {
                'fillcolor': 'yellow',
            },
            'stage_node': {
                'fillcolor': 'blue',
                'shape': 'rectangle',
            },
            'group_node': {
                'fillcolor': 'green',
                'shape': 'rectangle',
            },
            'default_edge': {
            },
            'global_graph': {
                'overlap': 'false',
                'splines': 'curved',
                'pack': 'true',
                'sep': '1,1',
                'esep': '0.8,0.8',
            },
            'global_node': {
                'style': 'filled',
                'shape': 'ellipse',
            },
            'global_edge': {
                'style': 'solid',
                'arrowhead': 'vee',
            },
        }

    def clear(self):
        self.graph.clear()
        self.data = {}
        self.workbook = []

    def node_options(self, id):
        if self.data.get(id, {}).get('type', None) == 'stage':
            return self.options['stage_node']
        if self.data.get(id, {}).get('type', None) == 'group':
            return self.options['group_node']
        return self.options['default_node']

    def edge_options(self, id_from, id_to):
        return self.options['default_edge']

    def add_graph_node(self, id, options=None):
        IO.debug('Add graph node: "%s"' % id)
        if id not in self.data:
            return
        if not options:
            options = self.node_options(id)
        self.graph.add_node(id, options)

    def add_graph_edge(self, id_from, id_to, options=None):
        IO.debug('Add graph edge: "%s" -> "%s"' % (id_from, id_to))
        if id_from not in self.data:
            return
        if id_to not in self.data:
            return
        if not options:
            options = self.edge_options(id_from, id_to)
        self.graph.add_edge(id_from, id_to, options)

    @staticmethod
    def filter_nodes(node_id, node, filter=None):
        # if group is not specified accept only the group tasks
        # and show only them on the graph/list
        # if there is a group, filter out group tasks
        # and show only normal tasks in this group

        type = node.get('type', None)

        # accept only group if there is no filter
        if not filter:
            return type == 'group'

        # drop groups if there is filter
        if type == 'group':
            return False

        # always accept 'stage' tasks
        if type == 'stage':
            return True

        # accept task only if it has matching group or role
        # or its group or role is set to 'any'
        if 'groups' in node:
            if ('*' in node['groups']) or (filter in node['groups']):
                return True

            for group in node['groups']:
                pattern = re.compile(group.strip('/'))
                if pattern.match(node_id):
                    return True
        return False

    def process_data(self):
        for node in self.workbook:
            if not isinstance(node, dict):
                continue
            # id and type are mandatory
            if not node.get('id', None):
                continue
            if not node.get('type', None):
                continue
            # requires and groups are mandatory
            if not 'requires' in node:
                node['requires'] = []
            if not isinstance(node['requires'], list):
                node['requires'] = [node['requires']]
            if not 'groups' in node:
                node['groups'] = []
            if not isinstance(node['groups'], list):
                node['groups'] = [node['groups']]
            # add role to groups ad drop role
            if 'role' in node:
                if not isinstance(node['role'], list):
                    node['role'] = [node['role']]
                node['groups'] += node['role']
                node.pop('role')
            self.data[node['id']] = node

    def resolve_cross_links(self):
        for node_id in self.data.keys():
            node = self.data[node_id]
            # resolve required_for to requires
            # print node.get('required_for', None)
            if 'required_for' in node:
                for require_id in node['required_for']:
                    IO.debug("Node: %s is required by node: %s" %
                             (node_id, require_id))
                    self.data[require_id]['requires'].append(node_id)
                node.pop('required_for')
            # resolve tasks to groups
            if 'tasks' in node:
                for task_id in node['tasks']:
                    IO.debug("Node: %s is included to node: %s" %
                             (task_id, node_id))
                    self.data[task_id]['groups'].append(node_id)
                node.pop('tasks')

    def filter_processed_data(self, filter=None):
        for node_id in self.data.keys():
            if not self.filter_nodes(node_id, self.data[node_id],
                                     filter=filter):
                self.data.pop(node_id)

    def build_graph(self):
        for node_id in self.data.keys():
            self.add_graph_node(node_id)
            for link in self.data[node_id]['requires']:
                self.add_graph_edge(link, node_id)

    @property
    def max_task_id_length(self):
        if self._max_task_id_length:
            return self._max_task_id_length
        self._max_task_id_length = len(max(self.data.keys(), key=len))
        return self._max_task_id_length

    def make_dot_graph(self):
        return networkx.to_agraph(self.graph)

    def show_topology(self):
        number = 1
        for node in networkx.topological_sort(self.graph):
            type = self.data.get(node, {}).get('type', None)
            if type == 'stage':
                node = '<' + node + '>'
            IO.output(number, fill=5, newline=False)
            IO.output(node, fill=self.max_task_id_length + 1)
            number += 1

    def create_image(self, img_file):
        try:
            pygraphviz
        except NameError:
            IO.output('You need "pygraphviz" to draw the graph. '
                      'But you can use -t to view the topology.')
            sys.exit(1)
        graph = self.make_dot_graph()
        for attr_name in self.options['global_graph']:
            graph.graph_attr[attr_name] = \
                self.options['global_graph'][attr_name]
        for attr_name in self.options['global_node']:
            graph.node_attr[attr_name] = \
                self.options['global_node'][attr_name]
        for attr_name in self.options['global_edge']:
            graph.edge_attr[attr_name] = \
                self.options['global_edge'][attr_name]
        graph.layout(prog=self.options['prog'])
        graph.draw(img_file)

    def load_data(self, workbook):
        if type(workbook) == list:
            self.workbook += workbook

    def load_yaml(self, yaml_data):
        workbook = yaml.load(yaml_data)
        if type(workbook) == list:
            self.workbook += workbook

    def load_yaml_file(self, yaml_file):
        if os.path.isfile(yaml_file):
            IO.debug("Reading file: '%s'" % yaml_file)
            yaml_file_stream = open(yaml_file, 'r')
            self.load_yaml(yaml_file_stream)
            yaml_file_stream.close()

    def write_dot(self, dot_file):
        graph = self.make_dot_graph()
        graph.write(dot_file)


if __name__ == '__main__':
    IO.main()
