import os
from time import sleep
import keystoneclient.v2_0
from quantumclient.v2_0 import client as q_client
import glanceclient
import subprocess

CIRROS_IMAGE = 'cirros-0.3.0-x86_64-disk.img'
CIRROS_IMAGE_URL = 'http://srv08-srt.srt.mirantis.net/' + 'cirros-0.3.0-x86_64-disk.img'
IMAGE_NAME = 'cirros_0.3.0'

here = lambda *x: os.path.join(os.path.abspath(os.path.dirname(__file__)), *x)
REPOSITORY_ROOT = here('..')
root = lambda *x: os.path.join(os.path.abspath(REPOSITORY_ROOT), *x)


class PrepareTempest():
    def __init__(self, username, password, tenant, public_ip, internal_ip):
        self.username = username
        self.password = password
        self.tenant = tenant
        self.public_ip = public_ip
        self.internal_ip = internal_ip

    def get_auth_url(self):
        print "auth_url", 'http://%s:5000/v2.0/' % self.public_ip
        return 'http://%s:5000/v2.0/' % self.public_ip

    def get_keystone(self):
        keystone = retry(10, keystoneclient.v2_0.client.Client,
                         username=self.username,
                         password=self.password,
                         tenant_name=self.tenant,
                         auth_url=self.get_auth_url())

        return keystone

    def get_quantum(self):
        quantum = retry(10, q_client.Client,
                                  username=self.username,
                                  password=self.password,
                                  tenant_name=self.tenant,
                                  auth_url=self.get_auth_url())
        return quantum

    def get_glance(self):
        keystone = self.get_keystone()
        endpoint = keystone.service_catalog.url_for(service_type='image',
                                                    endpoint_type='publicURL')

        return glanceclient.Client('1', endpoint=endpoint, token=keystone.auth_token)

    def prepare_tempest_essex(self, template_essex):
        image_ref, image_ref_alt, net_id, router_id = self.make_tempest_objects()
        self._tempest_write_config(self._tempest_config_essex(template_essex,
                                                              image_ref,
                                                              image_ref_alt)
        )

    def prepare_tempest_folsom(self, template_folsom):
        image_ref, image_ref_alt, net_id, router_id = self.make_tempest_objects()
        self._tempest_write_config(self._tempest_config_folsom(template=template_folsom,
                                                               image_ref=image_ref,
                                                               image_ref_alt=image_ref_alt,
                                                               path_to_private_key=root('fuel_test', 'config', 'ssh_keys', 'openstack'),
                                                               compute_db_uri='mysql://nova:nova@%s/nova' % self.internal_ip)
        )

    def prepare_tempest_grizzly(self, template_grizzly):
        image_ref, image_ref_alt, net_id, router_id = self.make_tempest_objects()
        self._tempest_write_config(self._tempest_config_grizzly(template=template_grizzly,
                                                                image_ref=image_ref,
                                                                image_ref_alt=image_ref_alt,
                                                                public_network_id=net_id,
                                                                public_router_id=router_id,
                                                                path_to_private_key=root('fuel_test', 'config', 'ssh_keys', 'openstack'),
                                                                compute_db_uri='mysql://nova:nova@%s/nova' % self.internal_ip)
        )

    def make_tempest_objects(self):
        keystone = self.get_keystone()
        tenants = self._get_tenants(keystone, 'tenant1', 'tenant2')
        if len(tenants) > 1:
            tenant1 = tenants[0].id
            tenant2 = tenants[1].id
        else:
            tenant1 = retry(10, keystone.tenants.create, tenant_name='tenant1')
            tenant2 = retry(10, keystone.tenants.create, tenant_name='tenant2')

        users = self._get_users(keystone, 'tempest1', 'tempest2')
        if len(users) == 0:
            retry(10, keystone.users.create, name='tempest1', password='secret',
                  email='tempest1@example.com', tenant_id=tenant1.id)
            retry(10, keystone.users.create, name='tempest2', password='secret',
                  email='tempest2@example.com', tenant_id=tenant2.id)

        image_ref, image_ref_alt = self._tempest_add_images()
        net_id, router_id = self._tempest_get_netid_routerid()

        return image_ref, image_ref_alt, net_id, router_id

    def _get_tenants(self, keystone, name1, name2):
        """ Retrieve all tenants with a certain names """
        tenants = [x for x in keystone.tenants.list() if x.name == name1 or x.name == name2]
        return tenants

    def _get_users(self, keystone, name1, name2):
        """ Retrieve all users with a certain names """
        users = [x for x in keystone.users.list() if x.name == name1 or x.name == name2]
        return users

    def _get_images(self, glance, name):
        """ Retrieve all images with a certain name """
        images = [x for x in glance.images.list() if x.name == name]
        return images

    def _upload(self, glance, name, path):
        image = glance.images.create(name=name, is_public=True, container_format='bare', disk_format='qcow2')
        image.update(data=open(path, 'rb'))
        return image.id

    def _tempest_add_images(self):
        if not os.path.isfile(CIRROS_IMAGE):
            subprocess.check_call(['wget', CIRROS_IMAGE_URL])

        glance = self.get_glance()
        images = self._get_images(glance, IMAGE_NAME)
        if len(images) > 1:
            return images[0].id, images[1].id
        else:
            return self._upload(glance, IMAGE_NAME, CIRROS_IMAGE), self._upload(glance, IMAGE_NAME, CIRROS_IMAGE)

    def _tempest_get_netid_routerid(self):
        networking = self.get_quantum()
        params = {'router:external': True}
        # Assume only 1 ext net and 1 ext router exists
        network = networking.list_networks(**params)['networks'][0]['id']
        router = networking.list_routers()['routers'][0]['id']

        return network, router

    def _tempest_write_config(self, config):
        with open(root('..', 'tempest.conf'), 'w') as f:
            f.write(config)

    def _tempest_config_essex(self, template, image_ref, image_ref_alt):
        sample = load(template)
        config = sample % {
            'HOST': self.public_ip,
            'USERNAME': 'tempest1',
            'PASSWORD': 'secret',
            'TENANT_NAME': 'tenant1',
            'ALT_USERNAME': 'tempest2',
            'ALT_PASSWORD': 'secret',
            'ALT_TENANT_NAME': 'tenant2',
            'IMAGE_ID': image_ref,
            'IMAGE_ID_ALT': image_ref_alt,
            'ADMIN_USERNAME': self.username,
            'ADMIN_PASSWORD': self.password,
            'ADMIN_TENANT_NAME': self.tenant,
        }

        return config

    def _tempest_config_folsom(self, template, image_ref, image_ref_alt, path_to_private_key, compute_db_uri='mysql://user:pass@localhost/nova'):
        sample = load(template)
        config = sample % {
            'IDENTITY_USE_SSL': 'false',
            'IDENTITY_HOST': self.public_ip,
            'IDENTITY_PORT': '5000',
            'IDENTITY_API_VERSION': 'v2.0',
            'IDENTITY_PATH': 'tokens',
            'IDENTITY_STRATEGY': 'keystone',
            'COMPUTE_ALLOW_TENANT_ISOLATION': 'true',
            'COMPUTE_ALLOW_TENANT_REUSE': 'true',
            'USERNAME': 'tempest1',
            'PASSWORD': 'secret',
            'TENANT_NAME': 'tenant1',
            'ALT_USERNAME': 'tempest2',
            'ALT_PASSWORD': 'secret',
            'ALT_TENANT_NAME': 'tenant2',
            'IMAGE_ID': image_ref,
            'IMAGE_ID_ALT': image_ref_alt,
            'FLAVOR_REF': '1',
            'FLAVOR_REF_ALT': '2',
            'COMPUTE_BUILD_INTERVAL': '10',
            'COMPUTE_BUILD_TIMEOUT': '600',
            'RUN_SSH': 'false',
            'NETWORK_FOR_SSH': 'novanetwork',
            'COMPUTE_CATALOG_TYPE': 'compute',
            'COMPUTE_CREATE_IMAGE_ENABLED': 'true',
            'COMPUTE_RESIZE_AVAILABLE': 'true',
            'COMPUTE_CHANGE_PASSWORD_AVAILABLE': 'false',
            'COMPUTE_LOG_LEVEL': 'DEBUG',
            'COMPUTE_WHITEBOX_ENABLED': 'true',
            'COMPUTE_SOURCE_DIR': '/opt/stack/nova',
            'COMPUTE_CONFIG_PATH': '/etc/nova/nova.conf',
            'COMPUTE_BIN_DIR': '/usr/local/bin',
            'COMPUTE_PATH_TO_PRIVATE_KEY': path_to_private_key,
            'COMPUTE_DB_URI': compute_db_uri,
            'IMAGE_CATALOG_TYPE': 'image',
            'IMAGE_API_VERSION': '1',
            'IMAGE_HOST': self.public_ip,
            'IMAGE_PORT': '9292',
            'IMAGE_USERNAME': 'tempest1',
            'IMAGE_PASSWORD': 'secret',
            'IMAGE_TENANT_NAME': 'tenant1',
            'COMPUTE_ADMIN_USERNAME': self.username,
            'COMPUTE_ADMIN_PASSWORD': self.password,
            'COMPUTE_ADMIN_TENANT_NAME': self.tenant,
            'IDENTITY_ADMIN_USERNAME': self.username,
            'IDENTITY_ADMIN_PASSWORD': self.password,
            'IDENTITY_ADMIN_TENANT_NAME': self.tenant,
            'VOLUME_CATALOG_TYPE': 'volume',
            'VOLUME_BUILD_INTERVAL': '10',
            'VOLUME_BUILD_TIMEOUT': '300',
            'NETWORK_CATALOG_TYPE': 'network',
            'NETWORK_API_VERSION': 'v2.0',
            }

        return config

    def _tempest_config_grizzly(self, template, image_ref, image_ref_alt, public_network_id, public_router_id, path_to_private_key,
                                compute_db_uri='mysql://nova:secret@localhost/nova'):
        sample = load(template)
        config = sample % {
            'IDENTITY_CATALOG_TYPE': 'identity',
            'IDENTITY_DISABLE_SSL_CHECK': 'true',
            'IDENTITY_USE_SSL': 'false',
            'IDENTITY_URI': 'http://%s:5000/v2.0/' % self.public_ip,
            'IDENTITY_STRATEGY': 'keystone',
            'IDENTITY_REGION': 'RegionOne',
            'USERNAME': 'tempest1',
            'PASSWORD': 'secret',
            'TENANT_NAME': 'tenant1',
            'ALT_USERNAME': 'tempest2',
            'ALT_PASSWORD': 'secret',
            'ALT_TENANT_NAME': 'tenant2',
            'ADMIN_USER_NAME': self.username,
            'ADMIN_PASSWORD': self.password,
            'ADMIN_TENANT_NAME': self.tenant,
            'COMPUTE_ALLOW_TENANT_ISOLATION': 'false',
            'COMPUTE_ALLOW_TENANT_REUSE': 'true',
            'IMAGE_ID': image_ref,
            'IMAGE_ID_ALT': image_ref_alt,
            'FLAVOR_REF': '1',
            'FLAVOR_REF_ALT': '1', # skip flavor '2' which provides 20Gb ephemerals and lots of RAM...
            'COMPUTE_BUILD_INTERVAL': '10',
            'COMPUTE_BUILD_TIMEOUT': '600',
            'RUN_SSH': 'false',
            'SSH_USER': 'cirros',
            'NETWORK_FOR_SSH': 'net04', # todo use private instead of floating?
            'COMPUTE_CATALOG_TYPE': 'compute',
            'COMPUTE_CREATE_IMAGE_ENABLED': 'true',
            'COMPUTE_RESIZE_AVAILABLE': 'true', # not supported with QEMU...
            'COMPUTE_CHANGE_PASSWORD_AVAILABLE': 'true',
            'LIVE_MIGRATION': 'true',
            'USE_BLOCKMIG_FOR_LIVEMIG' : 'true',
            'COMPUTE_WHITEBOX_ENABLED': 'true',
            'COMPUTE_SOURCE_DIR': '/opt/stack/nova',
            'COMPUTE_CONFIG_PATH': '/etc/nova/nova.conf',
            'COMPUTE_BIN_DIR': '/usr/local/bin',
            'COMPUTE_DB_URI': compute_db_uri,
            'COMPUTE_PATH_TO_PRIVATE_KEY': path_to_private_key,
            'COMPUTE_ADMIN_USERNAME': self.username,
            'COMPUTE_ADMIN_PASSWORD': self.password,
            'COMPUTE_ADMIN_TENANT_NAME': self.tenant,
            'IMAGE_CATALOG_TYPE': 'image',
            'IMAGE_API_VERSION': '1',
            'NETWORK_API_VERSION': 'v1.1',
            'NETWORK_CATALOG_TYPE': 'network',
            'TENANT_NETWORK_CIDR': '192.168.112.0/24', #TODO: ask Bogdan why # choose do not overlap with 'net04'
            'TENANT_NETWORK_MASK_BITS': '28', # 29 is too less to test quantum quotas (at least 50 ips needed)
            'TENANT_NETS_REACHABLE': 'false',
            'PUBLIC_NETWORK_ID': public_network_id,
            'PUBLIC_ROUTER_ID': public_router_id,
            'QUANTUM': 'true',
            'VOLUME_CATALOG_TYPE': 'volume',
            'VOLUME_BUILD_INTERVAL': '15',
            'VOLUME_BUILD_TIMEOUT': '400',
            }

        return config

def retry(count, func, **kwargs):
    i = 0
    while True:
        try:
            return func(**kwargs)
        except:
            if i >= count:
                raise
            i += 1
            sleep(1)

def load(path):
    with open(path) as f:
        return f.read()
