import os
from ci import Ci
from ciswift import CiSwift
from ciopenstackswift import CiOpenstackSwift


def get_ci(image=None):
    name = os.environ.get('ENV_NAME','recipes')
    if name == 'recipes-swift':
        ci = CiSwift(image,name)
    elif name == 'recipes-openstack-swift':
        ci = CiOpenstackSwift(image,name)
    else:
        ci = Ci(image,name)
    return ci


def get_environment_or_create(image=None):
    return get_ci(image).get_environment_or_create()


def get_environment():
    return get_ci().get_environment()
