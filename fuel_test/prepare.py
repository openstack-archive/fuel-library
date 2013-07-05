import argparse
import os
from fuel_test.prepare_tempest import PrepareTempest
from fuel_test.prepare_tempest_ci import PrepareTempestCI

here = lambda *x: os.path.join(os.path.abspath(os.path.dirname(__file__)), *x)
REPOSITORY_ROOT = here('..')
root = lambda *x: os.path.join(os.path.abspath(REPOSITORY_ROOT), *x)

class Prepare(object):
    def __init__(self, username=None, password=None, tenant=None, public_ip=None, internal_ip=None, ci=False, mode=False):
        if not ci:
            self.prepare_tempest = PrepareTempest(username=username,
                                                  password=password,
                                                  tenant=tenant,
                                                  public_ip=public_ip,
                                                  internal_ip=internal_ip)
        else:
            self.prepare_tempest = PrepareTempestCI(ha=mode)

    def prepare_tempest_folsom(self):
        template = root('fuel_test', 'config', 'tempest.conf.folsom.sample')
        self.prepare_tempest.prepare_tempest_folsom(template)

    def prepare_tempest_grizzly(self):
        template = root('fuel_test', 'config', 'tempest.conf.grizzly.sample')
        self.prepare_tempest.prepare_tempest_grizzly(template)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-r", "--release", help="openstack release under test", default="grizzly")
    parser.add_argument("-u", "--username", help="administrator name", default="admin")
    parser.add_argument("-p", "--password", help="administrator password", default="nova")
    parser.add_argument("-t", "--tenant", help="default tenant name", default="admin")
    parser.add_argument("-b", "--public_ip", help="public or virtual ip of controller", default=None)
    parser.add_argument("-i", "--internal_ip", help="internal or virtual ip of controller", default=None)
    parser.add_argument("-c", "--ci", default=True)
    parser.add_argument("-s", "--simple", default=False)
    args = vars(parser.parse_args())

    prepare = Prepare(username=args['username'],
                      password=args['password'],
                      tenant=args['tenant'],
                      public_ip=args['public_ip'],
                      internal_ip=args['internal_ip'],
                      mode=args['simple'],
                      ci=args['ci'])

    if args['release'] == "grizzly":
        prepare.prepare_tempest_grizzly()
    else:
        prepare.prepare_tempest_folsom()

if __name__ == '__main__':
    main()
