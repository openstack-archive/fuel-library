#!/usr/bin/env python
import sys
import argparse
import time

import subprocess
from xml.dom.minidom import *


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
        @return: Pretty-printed nodes structure
        """
        import pprint
        printer = pprint.PrettyPrinter(indent=2)
        return printer.pformat(self.nodes)

    def __str__(self):
        return self.xml

    def __repr__(self):
        self.show_nodes()

    def get_cib_from_file(self, cib_file=None):
        """
        Get cib XML DOM structure by reading xml file
        @param cib_file: Path to file (cibadmin -Q > cib.xml)
        @return: XML document
        """
        self.cib_file = cib_file
        self.xml = xml.dom.minidom.parse(self.cib_file)
        if not self.xml:
            raise StandardError('Could not get CIB from file!')
        return self.xml

    def get_cib_from_pacemaker(self):
        """
        Get cib XML DOM from Pacemaker by calling cibadmin
        @return: XML document
        """
        shell = False
        cmd = ['/usr/sbin/cibadmin', '--query']
        exception = 'Could not get CIB using cibadmin!'

        try:
            popen = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                shell=shell,
            )

            status_code = popen.wait()
            stdout = popen.stdout
            stderr = popen.stderr

            cib = stdout.read()
            exception += ' ' + stderr.read()
        except:
            raise StandardError(exception)
        if status_code != 0 or len(cib) == 0:
            raise StandardError(exception)
        else:
            self.xml = xml.dom.minidom.parseString(cib)
        if not self.xml:
            raise StandardError(exception)
        return self.xml

    def decode_lrm_op(self, lrm_op_block):
        """
        Decode operation block of lrm section
        @param lrm_op_block: Op block of the XML document
        @return: Operation structure
        """
        op = {}
        for op_attribute in lrm_op_block.attributes.keys():
            op[op_attribute] = lrm_op_block.attributes[op_attribute].value
        return op

    def get_call_id(self, op):
        """
        Helper used to sort ops list
        @param op Operation structure
        @return: call-id integer
        """
        try:
            return int(op['call-id'])
        except (KeyError, ValueError):
            return 0

    def decode_lrm_resource(self, lrm_resource_block):
        """
        Decode resource block of lrm section
        @param lrm_resource_block: Resource block of the XML document
        @return: Resource structure
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

        resource['ops'].sort(key=self.get_call_id)
        resource['status'] = self.determine_resource_status(resource['ops'])

        return resource

    def decode_lrm_node(self, lrm_node_block):
        """
        Decode node block of lrm section
        @param lrm_node_block: Node block of the XML document
        @return: Node structure
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
        @return: Nodes structure
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
        return self.nodes

    def determine_resource_status(self, ops):
        """
        Determite the status of a resource by analyzing
        last lrm operations.
        @param ops: Operations array
        @return: Resource status string
        """
        last_op = None

        for op in ops:
            self.interface.debug('Status Op: %s' % op, 3, 3)
            # skip incomplite ops
            if not op.get('op-status', None) == '0':
                continue

            # skip useless operations
            if not op.get('operation', None) in ['start', 'stop', 'monitor', 'promote']:
                continue

            # skip unsuccessfull operations
            if not (op.get('rc-code', None) == '0' or op.get('operation', None) == 'monitor'):
                continue

            last_op = op

        if not last_op:
            return '?'

        if last_op.get('operation', None) in ['promote', 'start', 'stop']:
            status = last_op['operation']
        elif last_op.get('rc-code', None) in ['0', '8']:
            status = 'start'
        else:
            status = 'stop'

        self.interface.debug('Status: %s' % status, 3, 3)
        return status
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

    def __str__(self):
        return self.escape()

    def __repr__(self):
        return "Color(fgcode=%s, bgcode=%s, attrcode=%s, enabled=%s, brightfg=%s, brightbg=%s)" % (
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
        self.title_color = Color(fgcode='blue')

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
        self.parser.add_argument("-v", "--verbose", help="show more information (timings)", action='store_true')
        self.parser.add_argument("-n", "--node", help="filter by node name", type=str)
        self.parser.add_argument("-p", "--primitive", help="filter by primitive name", type=str)
        self.parser.add_argument("-f", "--file", help="read CIB from file instead of Pacemaker", type=str)
        self.parser.add_argument("-y", "--yaml", help="output as YAML", action='store_true')
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
        @param msg: Message to write
        @param debug: Minimum debug level this message should be shown
        @param offset: Number of spaces before the message
        """
        if not offset:
            offset = debug

        if self.args.debug >= debug:
            sys.stderr.write('  ' * offset + str(msg) + "\n")

    def puts(self, msg='', offset=0):
        """
        Print a string
        @param msg: String to print
        @param offset: Number of spaces before the string
        """
        sys.stdout.write('  ' * offset + str(msg) + "\n")

    def output(self, msg=''):
        """
        Print string without newline at the end
        @param msg: String to print
        """
        sys.stdout.write(str(msg))

    def rc_code_to_string(self, rc_code):
        """
        Convert rc_code number to human-readable string
        @param rc_code: Return code (one digit)
        @return: Colored operation status string
        """
        rc_code = str(rc_code)
        if rc_code in self.ocf_rc_codes:
            return self.ocf_rc_codes[rc_code]
        else:
            return self.error_color('Unknown!')

    def status_color(self, status, line):
        """
        Colorize a line according to the resource status
        @param status: Resource status string
        @param line: A line to be colorized
        @return: Colorized line
        """
        status = str(status)
        line = str(line)
        if status in ['promote', 'start']:
            return self.running_color(line)
        if status in ['stop']:
            return self.not_running_color(line)
        else:
            return self.title_color(line)

    def print_resource(self, resource, offset=4):
        """
        Print resource description block
        @param resource: Resource structure
        @param offset: Number of spaces before the block
        """
        resource = resource.copy()
        resource['id'] = self.status_color(resource['status'], resource['id'])
        resource['status-string'] = self.status_color(resource['status'], resource['status'].title())
        line = "> %(id)s (%(class)s::%(provider)s::%(type)s) %(status-string)s" % resource
        self.puts(line, offset)

    def seconds_to_time(self, seconds_from, seconds_to=None, msec=False):
        """
        Convert two timestampt to human-readable time delta between them
        @param seconds_from: timestamp to count from
        @param seconds_to: timestamp to coumt to (default: now)
        @param msec: input is in miliseconds instead of seconds
        @return: String of time delta
        """
        seconds_in_day = 86400
        seconds_in_hour = 3600
        seconds_in_minute = 60
        miliseconds_in_second = 1000

        try:
            if seconds_to is None:
                seconds_to = time.time()
            elif msec:
                seconds_to = float(seconds_to) / miliseconds_in_second
            else:
                seconds_to = float(seconds_to)

            if msec:
                seconds_from = float(seconds_from) / miliseconds_in_second
            else:
                seconds_from = float(seconds_from)

        except TypeError:
            return '?'

        seconds = abs(seconds_to - seconds_from)

        if seconds > seconds_in_day:
            days = int(seconds / seconds_in_day)
            seconds -= seconds_in_day * days
        else:
            days = 0

        if seconds > seconds_in_hour:
            hours = int(seconds / seconds_in_hour)
            seconds -= seconds_in_hour * hours
        else:
            hours = 0

        if seconds > seconds_in_minute:
            minutes = int(seconds / seconds_in_minute)
            seconds -= seconds_in_minute * minutes
        else:
            minutes = 0

        seconds, miliseconds = int(seconds), int((seconds - int(seconds)) * miliseconds_in_second)

        return_string = []

        if days > 0:
            return_string.append(str(days) + 'd')

        if hours > 0:
            return_string.append(str(hours) + 'h')

        if minutes > 0:
            return_string.append(str(minutes) + 'm')

        # show at least seconds even if all is zero
        if seconds > 0 or miliseconds == 0:
            return_string.append(str(seconds) + 's')

        # who cares about miliseconds when we are talking about minutes
        if miliseconds > 0 and minutes == 0:
            return_string.append(str(miliseconds) + 'ms')

        return ':'.join(return_string)

    def print_op(self, op, offset=8):
        """
        Print operation description block
        @param op: Operation structure
        @param offset: Number of spaces before the string
        """
        op = op.copy()
        self.debug(str(op), 3)
        op['rc-code-string'] = self.rc_code_to_string(op.get('rc-code', None))

        if 'interval' in op:
            op['interval-string'] = self.seconds_to_time(op['interval'], 0, msec=True)

        if ('interval' in op) and (op['interval'] != '0'):
            op['operation-string'] = '%s (%s)' % (op['operation'], op['interval-string'])
        else:
            op['operation-string'] = op['operation']

        line = '* %(operation-string)s %(rc-code-string)s' % op
        self.puts(line, offset)

        if self.args.verbose:
            # calculate and show timings
            if 'exec-time' in op:
                op['exec-time-sec'] = self.seconds_to_time(op['exec-time'], 0, msec=True)

            if 'last-run' in op:
                op['last-run-sec'] = self.seconds_to_time(op['last-run'])

            if 'last-rc-change' in op:
                op['last-rc-change-sec'] = self.seconds_to_time(op['last-rc-change'])

            line = ''
            #
            # if 'crm-debug-origin' in op:
            #     line += 'Origin: %(crm-debug-origin)s' % op

            if 'last-run-sec' in op:
                line += ' LastRun: %(last-run-sec)s' % op

            if 'last-rc-change-sec' in op:
                line += ' LastChange: %(last-rc-change-sec)s' % op

            if 'exec-time-sec' in op:
                line += ' ExecTime: %(exec-time-sec)s' % op
            #
            # if 'interval-string' in op:
            #     line += ' Interval: %(interval-string)s' % op

            self.puts(line, offset + 2)

    def print_node(self, node):
        """
        Print node description block
        @param node: Node structure
        """
        line = '%s\n%s\n%s' % (40 * '=', node['id'], 40 * '=')
        self.puts(line)

    def print_table(self):
        """
        Print the entire output table
        """
        for node_id, node_data in sorted(self.cib.nodes.items()):
            if self.args.node:
                if node_id != self.args.node:
                    continue
            self.print_node(node_data)
            for resource_id, resource_data in sorted(node_data['resources'].items()):
                if self.args.primitive:
                    if resource_id != self.args.primitive:
                        continue
                self.print_resource(resource_data)
                for op in resource_data['ops']:
                    self.print_op(op)

###########################################################################################################

if __name__ == '__main__':
    interface = Interface()
    interface.create_cib()
    interface.cib.decode_lrm()
    interface.print_table()
