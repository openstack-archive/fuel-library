#!/usr/bin/env python
import fnmatch
import os
import argparse
import pygraphviz as pgv
import yaml


class MakeGraph:
    def __init__(self):
        self._data = {}
        self._workbook = []
        self._graph = None
        self._topology = None
        self.new_graph()

    options = {
        'debug': False,
        'prog': 'dot',
        'default_node': {
            'shape': 'ellipse',
            'fillcolor': 'yellow',
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
        },
        'global_edge': {
            'style': 'solid',
            'arrowhead': 'vee',
        },
        'non_task_types': [
            'role',
            'stage',
        ]
    }

    def debug_print(self, msg):
        if self.options.get('debug', False):
            print msg

    def new_graph(self):
        self._graph = pgv.AGraph(strict=False, directed=True)

    # graph functions

    def graph_node(self, id, options=None):
        if not options:
            options = {}
        for option, value in self.node_options(id).iteritems():
            if option not in options:
                options[option] = value
        self.debug_print("Node: %s (%s)" % (id, repr(options)))
        if not self.graph.has_node(id):
            self.graph.add_node(id)
        node = self.graph.get_node(id)
        for attr_name, attr_value in options.iteritems():
            node.attr[attr_name] = attr_value
        return node

    def graph_edge(self, from_node, to_node, options=None):
        if not options:
            options = {}
        for option, value in self.edge_options(from_node, to_node).iteritems():
            if option not in options:
                options[option] = value
        self.debug_print("Edge: %s -> %s (%s)" % (from_node, to_node, repr(options)))
        if not self.graph.has_edge(from_node, to_node):
            self.graph.add_edge(from_node, to_node)
        edge = self.graph.get_edge(from_node, to_node)
        for attr_name in options:
            edge.attr[attr_name] = options[attr_name]
        return edge

    def edge_options(self, from_node, to_node):
        return self.options['default_edge']

    def node_options(self, node):
        return self.options['default_node']

    # data functions

    # convert array data to hash data
    def convert_data(self, group=None):
        # form the initial data structure
        for node in self.workbook:
            if not type(node) is dict:
                continue
            if not node.get('type', None) and node.get('id', None):
                continue
            id = node.get('id', None)
            node_type = node.get('type', None)
            stage = node.get('stage', 'deployment')
            requires = node.get('requires', [])
            required_for = node.get('required_for', [])
            groups = node.get('groups', [])

            if node_type in self.options['non_task_types']:
                continue

            if group:
                if not ((group in groups) or (stage == group)):
                    continue

            self._data[id] = {
                'id': id,
                'requires': requires,
                'required_for': required_for + groups,
                'groups': groups,
                'type': node_type,
                'stage': stage,
            }

        # clen the data dictionary
        cleaned_data = {}
        for node in self.data.iterkeys():

            # node structure
            id = self.data[node].get('id', None)
            node_type = self.data[node].get('type', None)
            stage = self.data[node].get('stage', None)
            groups = self.data[node].get('groups', [])
            cleaned_data[node] = {
                'id': id,
                'type': node_type,
                'links': [],
                'stage': stage,
                'groups': groups,
            }

        # convert links
        for node in cleaned_data:
            required_for = self.data[node]['required_for']
            requires = self.data[node]['requires']

            # cross-join requires and requires_for
            for reqf in required_for:
                if reqf in cleaned_data:
                    cleaned_data[node]['links'].append(reqf)
            for req in requires:
                if req in cleaned_data:
                    cleaned_data[req]['links'].append(node)

        # clean links
        for node in cleaned_data:
            links = cleaned_data[node]['links']
            filtered_links = []

            # find if there are some links to tasks
            has_task_links = False
            for link in links:
                if self.node_type(link) != 'role':
                    has_task_links = True

            # keep links to roles only if there are no links to tasks
            for link in links:
                if has_task_links and self.node_type(link) == 'role':
                    continue
                filtered_links.append(link)

            cleaned_data[node]['links'] = filtered_links

        # save cleaned data to the object
        self._data = cleaned_data
        return self._data

    # build graph structure using data
    def build_graph(self):
        for id, node in self.data.iteritems():
            self.graph_node(id)
            for link in node['links']:
                self.graph_edge(id, link)

    def build_topology(self):
        import networkx as nx
        self._topology = nx.DiGraph()
        for id, node in self.data.iteritems():
            self._topology.add_node(id)
            for link in node['links']:
                self._topology.add_edge(id, link)

    def max_task_id_length(self):
        return len(max(self.data.keys(), key=len))

    def topology_sort(self):
        import networkx as nx
        self.build_topology()
        number = 1
        for task in nx.topological_sort(self.topology):
            groups = self.data.get(task, {}).get('groups', [])
            groups = ', '.join(groups)
            line = ''
            line += str(number).ljust(4)
            line += str(task).ljust(self.max_task_id_length() + 1)
            line += groups
            print line
            number += 1

    def node_exists(self, node):
        return node in self.data

    def node_type(self, node):
        if not self.node_exists(node):
            return None
        return self.data[node]['type']

    # IO functions

    def task_files(self, directory, file_pattern='*tasks.yaml'):
        if os.path.isfile(directory) and fnmatch.fnmatch(directory, file_pattern):
            yield directory
        for root, dirs, files in os.walk(directory):
            for file_name in files:
                if fnmatch.fnmatch(file_name, file_pattern):
                    task_path = os.path.join(root, file_name)
                    if not os.path.isfile(task_path):
                        continue
                    yield task_path

    def load_data(self, workbook):
        if type(workbook) == list:
            self._workbook += workbook

    def load_yaml(self, yaml_data):
        workbook = yaml.load(yaml_data)
        if type(workbook) == list:
            self._workbook += workbook

    def load_yaml_file(self, yaml_file):
        if os.path.isfile(yaml_file):
            self.debug_print("Reading file: '%s'" % yaml_file)
            yaml_file_stream = open(yaml_file, 'r')
            self.load_yaml(yaml_file_stream)
            yaml_file_stream.close()

    def write_dot(self, dot_file):
        self.graph.write(dot_file)

    def write_image(self, img_file):
        for attr_name in self.options['global_graph']:
            self.graph.graph_attr[attr_name] = self.options['global_graph'][attr_name]
        for attr_name in self.options['global_node']:
            self.graph.node_attr[attr_name] = self.options['global_node'][attr_name]
        for attr_name in self.options['global_edge']:
            self.graph.edge_attr[attr_name] = self.options['global_edge'][attr_name]
        self.graph.layout(prog=self.options['prog'])
        self.graph.draw(img_file)

    @property
    def workbook(self):
        return self._workbook

    @property
    def data(self):
        return self._data

    @property
    def graph(self):
        return self._graph

    @property
    def topology(self):
        return self._topology


parser = argparse.ArgumentParser()
parser.add_argument("--workbook", "-w", action="store_true", default=False, help='Output the raw workbook')
parser.add_argument("--clear_workbook", "-c", action="store_true", default=False, help='Output the clear workbook')
parser.add_argument("--dot", "-o", action="store_true", default=False, help='Output the graph in dot format')
parser.add_argument("--png", "-p", action="store_true", default=True, help='Write the graph in png format (default)')
parser.add_argument("--png_file", "-f", type=str, default='task_graph.png', help='Write graph image to this file')
parser.add_argument("--debug", "-d", action="store_true", default=False, help='Print debug messages')
parser.add_argument("--group", "-g", help="Group or stage to build the graph for", default=None)
parser.add_argument("--topology", "-t", action="store_true", help="Show the tasks topology (possible execution order)", default=False)
parser.add_argument('files', metavar='FILE', type=str, nargs='+',
                    help='The list of files of directories where tasks can be found', default=[])

args = parser.parse_args()

if args.topology and not args.group:
    args.group = 'deployment'

mg = MakeGraph()
mg.options['debug'] = args.debug

for file in args.files:
    for task_file in mg.task_files(file):
        mg.load_yaml_file(task_file)

if args.workbook:
    print yaml.dump(mg.workbook)
    exit(0)

mg.convert_data(args.group)
mg.build_graph()

if args.topology:
    mg.topology_sort()

if args.clear_workbook:
    print yaml.dump(mg.data)
    exit(0)

if args.dot:
    print mg.graph.to_string()
    exit(0)

mg.write_image(args.png_file)
