import xml.etree.ElementTree as ET
import argparse


parser = argparse.ArgumentParser()
parser.add_argument('-f', '--file', type=argparse.FileType('r'), help='xml file exported from Zabbix', required=True)
parser.add_argument('-x', '--exported', action='store_true', default=False, help='output as puppet exported resources')
parser.add_argument('-n', '--fqdn', action='store_true', default=False, help='include fqdn fact in namevar')
args = parser.parse_args()

xmldata = args.file.read()

templatelist = {}
itemlist = {}
triggerlist = {}
applicationlist = {}
hostgrouplist = {}


class ZabbixApi:
    root_tag = None
    puppet_type = None
    props = ['name']
    namevar_constructor = ['name']

    def __init__(self, e):
        self.blacklist = ['applications', 'groups', 'items', 'triggers', 'templates']
        self.e = e
        self.namevar = ''
        self.namevar_list = []
        if self.e.find('name') is not None:
            self.name = self.e.find('name').text
            for nc in self.namevar_constructor:
                self.namevar_list.append(self.e.find(nc).text)
            self.namevar = ' '.join(self.namevar_list)
        else:
            self.name = 'BROKEN'
            self.namevar = self.name
        self.props_child = {}
        self.aligner()
        self.children()

    def to_puppet_str(self, k, v, quote=True):
        if v:
            spaces = self.maxalign - len(k) + 1
            if quote:
                return '  ' + k + ' '*spaces + '=> \'' + v + '\','
            else:
                return '  ' + k + ' '*spaces + '=> ' + v + ','

    def to_puppet(self):
        if self.puppet_type:
            if args.exported:
                er = '@@'
            else:
                er = ''
            if args.fqdn:
                print er + self.puppet_type + ' { \'$::fqdn ' +  self.namevar + '\':'
            else:
                print er + self.puppet_type + ' { \'' +  self.namevar + '\':'
            for p in self.props:
                if (self.e.find(p) is not None) and (p not in self.blacklist):
                    pp = self.to_puppet_str(p, self.e.find(p).text)
                    if pp:
                        print pp
                if p in self.props_child:
                    print self.to_puppet_str(p, str(self.props_child[p]), False)
            print "}\n"

    def children(self):
        #Applications
        applications = self.e.findall("./applications/application")
        if applications is not None:
            for application in applications:
                zo = ZabbixApplication(application)
                if 'applications' in self.props_child:
                    if self.props_child['applications'].count(zo.name) == 0:
                        self.props_child['applications'].append(zo.name)
                else:
                    self.props_child['applications'] = [zo.name]
                applicationlist[zo.namevar] = zo
        #Items
        items = self.e.findall("./items/item")
        if items is not None:
            for item in items:
                zo = ZabbixItem(item)
                itemlist[zo.namevar] = zo
        #Hostgroups
        hostgroups = self.e.findall("./groups/group")
        if hostgroups is not None:
            for hostgroup in hostgroups:
                zo = ZabbixHostgroup(hostgroup)
                if 'group' in self.props_child:
                    if self.props_child['group'].count(zo.name) == 0:
                        self.props_child['group'].append(zo.name)
                else:
                    self.props_child['group'] = [zo.name]
                hostgrouplist[zo.namevar] = zo
        #Templates
        templates = self.e.findall("./templates/template")
        if templates is not None:
            for template in templates:
                zo = ZabbixTemplate(template)
                templatelist[zo.namevar] = zo
        #Triggers
        triggers = self.e.findall("./triggers/trigger")
        if triggers is not None:
            for trigger in triggers:
                zo = ZabbixTrigger(trigger)
                triggerlist[zo.namevar] = zo

    def aligner(self):
        self.maxalign = len(max(self.props, key=len))


class ZabbixApplication(ZabbixApi):
    puppet_type = 'zabbix_application'
    props = [ 'name' ]


class ZabbixTrigger(ZabbixApi):
    puppet_type = 'zabbix_trigger'
    props = [
        'name', 'description', 'expression', 'comments',
        'priority', 'status', 'type', 'url'
            ]

class ZabbixHostgroup(ZabbixApi):
    puppet_type = 'zabbix_hostgroup'
    props = [ 'name' ]


class ZabbixItem(ZabbixApi):
    puppet_type = 'zabbix_item'
    namevar_constructor = ['name', 'key']
    props = [
        'name', 'host', 'host_type', 'key',
        'delay', 'type', 'username',
        'value_type', 'authtype', 'data_type',
        'delay_flex', 'delta', 'description',
        'applications'
            ]


class ZabbixTemplate(ZabbixApi):
    root_tag = 'template'
    puppet_type = 'zabbix_template'
    props = [ 'name', 'group' ]


class ZabbixImport(ZabbixApi):
    root_tag = 'zabbix_export'
    puppet_type = None


root = ET.fromstring(xmldata)

if root.tag == 'zabbix_export':
    zi = ZabbixImport(root)

for k in templatelist.keys():
    templatelist[k].to_puppet()

for k in itemlist.keys():
    itemlist[k].to_puppet()

for k in triggerlist.keys():
    triggerlist[k].to_puppet()

for k in applicationlist.keys():
    applicationlist[k].to_puppet()

for k in hostgrouplist.keys():
    hostgrouplist[k].to_puppet()



