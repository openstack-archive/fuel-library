#!/usr/bin/env python
import os
import sys
import subprocess
import pprint
import argparse
from xml.dom.minidom import *


class Color:
    """
    A custom fancy colors class
    """
    def __init__(self, fgcode=None, bgcode=None, attrcode=0, enabled=True, brightfg=False, brightbg=False):
        self.start = "\033["
        self.end = "m"
        self.reset = self.start + "0" + self.end

        if enabled:
            self.enabled = True
        else:
            self.enabled = False

        if brightfg:
            self.brightfg = True
        else:
            self.brightfg = False

        if brightbg:
            self.brightbg = True
        else:
            self.brightbg = False

        self.fgoffset = 30
        self.bgoffset = 40
        self.brightoffset = 60

        self.colortable = {
            'black': 0,
            'red': 1,
            'green': 2,
            'yellow': 3,
            'blue': 4,
            'magneta': 5,
            'cyan': 6,
            'white': 7,
            'off': None,
        }

        self.attrtable = {
            'normal': 0,
            'bold': 1,
            'faint': 2,
            #'italic':    3,
            'underline': 4,
            'blink': 5,
            #'rblink':    6,
            'negative': 7,
            'conceal': 8,
            #'crossed':   9,
            'off': 0,
        }

        self.setFG(fgcode)
        self.setBG(bgcode)
        self.setATTR(attrcode)

    def toggle_enabled(self):
        if self.enabled:
            self.enabled = False
        else:
            self.enabled = True

    def toggle_brightfg(self):
        if self.brightfg:
            self.brightfg = False
        else:
            self.brightfg = True

    def toggle_brightbg(self):
        if self.brightbg:
            self.brightbg = False
        else:
            self.brightbg = True

    def setFG(self, color):
        if type(color) == int:
            self.fgcode = color
            return True
        if color in self.colortable:
            self.fgcode = self.colortable[color]
            return True
        self.fgcode = None
        return False

    def setBG(self, color):
        if type(color) == int:
            self.bgcode = color
            return True
        if color in self.colortable:
            self.bgcode = self.colortable[color]
            return True
        self.bgcode = None
        return False

    def setATTR(self, color):
        if type(color) == int:
            self.attrcode = color
            return True
        if color in self.attrtable:
            self.attrcode = self.attrtable[color]
            return True
        self.attrcode = 0
        return False

    def escape(self):
        components = []
        attrcode = self.attrcode

        if self.fgcode is not None:
            fgcode = self.fgoffset + self.fgcode
            if self.brightfg:
                fgcode += self.brightoffset
        else:
            fgcode = None

        if self.bgcode is not None:
            bgcode = self.bgoffset + self.bgcode
            if self.brightbg:
                bgcode += self.brightoffset
        else:
            bgcode = None

        components.append(attrcode)
        if fgcode:
            components.append(fgcode)
        if bgcode:
            components.append(bgcode)

        escstr = self.start + ";".join(map(str, components)) + self.end
        return escstr

    def printchart(self):
        for fg in range(0, 7):
            for bg in range(0, 7):
                for attr in sorted(self.attrtable.values()):
                    democolor = Color(fgcode=fg, bgcode=bg, attrcode=attr, brightfg=False, brightbg=False)
                    sys.stdout.write(democolor("Hello World!"), repr(democolor))
                    democolor.brightfg = True
                    sys.stdout.write(democolor("Hello World!"), repr(democolor))
                    democolor.brightbg = True
                    sys.stdout.write(democolor("Hello World!"), repr(democolor))

    def __str__(self):
        return self.escape()

    def __repr__(self):
        return "Color(fgcode=%d, bgcode=%d, attrcode=%d, enabled=%s, brightfg=%s, brightbg=%s)" % (
            self.fgcode,
            self.bgcode,
            self.attrcode,
            str(self.enabled),
            str(self.brightfg),
            str(self.brightbg),
        )

    def __call__(self, string):
        if self.enabled:
            return self.escape() + string + self.reset
        else:
            return string


class Interface:
    """
    Funcions related to input, output and formattiong of data
    """

    def __init__(self):
        self.error_color = Color(fgcode='red')
        self.running_color = Color(fgcode='green', brightfg=True)
        self.not_running_color = Color(fgcode=5, attrcode=0, enabled=True, brightfg=True, brightbg=False)
        self.debug_color = Color(fgcode=6, bgcode=5, attrcode=1, enabled=True, brightfg=False, brightbg=False)
        self.primitive_name_color = Color(fgcode='blue')

        self.ocf_rc_codes = {
            '0': self.running_color('Success'),
            '1': self.error_color('Error: Generic'),
            '2': self.error_color('Error: Arguments'),
            '3': self.error_color('Error: Unimplemented'),
            '4': self.error_color('Error: Permissions'),
            '5': self.error_color('Error: Installation'),
            '6': self.error_color('Error: Configuration'),
            '7': self.not_running_color('Not Running'),
            '8': self.running_color('Master Running'),
            '9': self.error_color('Master Failed'),
        }

        self.parser = argparse.ArgumentParser()
        self.parser.add_argument("-d", "--debug", help="debug output", type=int, choices=[0, 1, 2, 3], default=0)
        self.parser.add_argument("-n", "--node", help="filter by node name", type=str)
        self.parser.add_argument("-p", "--primitive", help="filter by primitive name", type=str)
        self.parser.add_argument("-f", "--file", help="read CIB from file instead of Pacemaker", type=str)
        self.args = self.parser.parse_args()

    def create_cib(self):
        """
        Creates a CIB instance either from file or from Pacemaker
        """
        self.cib = CIB(self)
        if self.args.file:
            self.cib.get_cib_from_file(self.args.file)
        else:
            self.cib.get_cib_from_pacemaker()

    def show_cib_nodes(self):
        """
        Print out parsed CIB nodes data
        """
        self.puts(self.cib.show_nodes())

    def debug(self, msg='', debug=1, offset=None):
        """
        Debug print string
        @param msg:
        @param debug:
        @param offset:
        """
        if not offset:
            offset = debug

        if self.args.debug >= debug:
            sys.stderr.write('  ' * offset + str(msg) + "\n")

    def puts(self, msg='', offset=0):
        """
        Print string
        @param msg:
        @param offset:
        """
        sys.stdout.write('  ' * offset + str(msg) + "\n")

    def output(self, msg=''):
        """
        Print string without newline
        @param msg:
        """
        sys.stdout.write(str(msg))

    def rc_code_to_string(self, rc_code):
        """
        Convert rc_code number to human-readable string
        @param rc_code:
        @return:
        """
        rc_code = str(rc_code)
        if rc_code in self.ocf_rc_codes:
            return self.ocf_rc_codes[rc_code]
        else:
            return self.error_color('Unknown!')

    def print_resource(self, resource, offset=4):
        """
        Print resource description block
        @param resource:
        @param offset:
        """
        resource = resource.copy()
        resource['id'] = self.primitive_name_color(resource['id'])
        line = "> %(id)s (%(class)s::%(provider)s::%(type)s)" % resource
        self.puts(line, offset)

    def print_op(self, op, offset=8):
        """
        Print operation description block
        @param op:
        @param offset:
        """
        op = op.copy()
        op['rc-code-string'] = self.rc_code_to_string(op['rc-code'])
        line = '* %(id)s %(rc-code-string)s' % op
        self.puts(line, offset)

    def print_node(self, node):
        """
        Print node description block
        @param node:
        """
        line = '%s\n%s\n%s' % (40 * '=', node['id'], 40 * '=')
        self.puts(line)

    def print_table(self):
        """
        Print the entire output table
        """
        for node_id, node_data in sorted(self.cib.nodes.items()):
            self.print_node(node_data)
            for resource_id, resource_data in sorted(node_data['resources'].items()):
                self.print_resource(resource_data)
                for op in resource_data['ops']:
                    self.print_op(op)


class CIB:
    """
    Works with CIB xml. Loads it and parses
    """

    def __init__(self, interface):
        self.nodes = {}
        self.interface = interface

    def show_nodes(self):
        """
        Return pretty printed node structure for debug purpose
        @return:
        """
        printer = pprint.PrettyPrinter(indent=2)
        return printer.pformat(self.nodes)

    def __str__(self):
        return self.xml

    def __repr__(self):
        self.show_nodes()

    def get_cib_from_file(self, cib_file=None):
        """
        Get cib XML DOM structure by reading xml file
        @param cib_file:
        """
        self.cib_file = cib_file
        self.xml = xml.dom.minidom.parse(self.cib_file)
        if not self.xml:
            raise StandardError('Could not get CIB from file!')

    def get_cib_from_pacemaker(self):
        """
        Get cib XML DOM from Pacemaker by calling cibadmin
        @return: @raise:
        """
        shell = False
        cmd = ['/usr/sbin/cibadmin', '--query']
        
        popen = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            shell=shell,
        )

        status_code = popen.wait()
        stdout = popen.stdout
        #stderr = popen.stderr

        cib = stdout.read()
        
        if status_code != 0 or len(cib) == 0:
            raise StandardError('Could not get CIB using cibadmin!')
        else:
            self.xml = xml.dom.minidom.parseString(cib)
            return self.xml

    def decode_lrm_op(self, lrm_op_block):
        """
        Decode operation block of lrm section
        @param lrm_op_block:
        @return:
        """
        op = {}
        for op_attribute in lrm_op_block.attributes.keys():
            op[op_attribute] = lrm_op_block.attributes[op_attribute].value
        return op

    def decode_lrm_resource(self, lrm_resource_block):
        """
        Decode resource block of lrm section
        @param lrm_resource_block:
        @return:
        """
        resource = {}

        for lrm_resource_attribute in lrm_resource_block.attributes.keys():
            resource[lrm_resource_attribute] = lrm_resource_block.attributes[lrm_resource_attribute].value
        resource['ops'] = []

        lrm_rsc_ops = lrm_resource_block.getElementsByTagName('lrm_rsc_op')

        for lrm_of_single_op in lrm_rsc_ops:
            if not (lrm_of_single_op.attributes and lrm_of_single_op.hasAttribute('id')):
                continue
            op = self.decode_lrm_op(lrm_of_single_op)
            self.interface.debug('Op: %s' % op['id'], 2, 3)
            resource['ops'].append(op)

        resource['ops'].sort(key=lambda o: o.get('call_id', '0'))
        resource['role'] = self.determine_resource_role(resource['ops'])

        return resource

    def decode_lrm_node(self, lrm_node_block):
        """
        Decode node block of lrm section
        @param lrm_node_block:
        @return:
        """
        node_data = {}

        node_id = lrm_node_block.attributes['id'].value
        node_data['id'] = node_id
        node_data['resources'] = {}

        lrm_of_all_resources = lrm_node_block.getElementsByTagName('lrm_resource')

        for lrm_of_single_resource in lrm_of_all_resources:
            if not (lrm_of_single_resource.attributes and lrm_of_single_resource.hasAttribute('id')):
                continue
            resource_id = lrm_of_single_resource.attributes['id'].value
            resource_data = self.decode_lrm_resource(lrm_of_single_resource)
            self.interface.debug('Resource: %s' % resource_id, 2, 2)
            node_data['resources'][resource_id] = resource_data

        return node_data

    def decode_lrm(self):
        """
        Find lrm sections and decode them
        @return:
        """
        lrm_of_all_nodes = self.xml.getElementsByTagName('lrm')
        if len(lrm_of_all_nodes) == 0:
            return None

        for lrm_of_single_node in lrm_of_all_nodes:
            if not (lrm_of_single_node.attributes and lrm_of_single_node.hasAttribute('id')):
                continue
            node_id = lrm_of_single_node.attributes['id'].value
            node_data = self.decode_lrm_node(lrm_of_single_node)
            self.interface.debug('Node: %s' % node_id, 2, 1)
            self.nodes[node_id] = node_data

    def determine_resource_role(self, ops):
        return 'Started'

###########################################################################################################

if __name__ == '__main__':
    interface = Interface()
    interface.create_cib()
    interface.cib.decode_lrm()
    #interface.show_cib_nodes()
    interface.print_table()
