#!/bin/sh
# It is a workaround for old pip and tox versions. CI uses tox 1.6 and it
# can't manage hash symbols right way (look at
# https://bitbucket.org/hpk42/tox/issues/181/hash-number-sign-cannot-be-escaped-in)
# We can use deps field for tox but at the same time CI uses pip 1.5.4 and it
# can't properly install package from a vcs subdirectory. Also we can't just
# update pip from tox deps as dependencies doesn't managed in a consequent way in tox.
# TODO(sbog): move this into tox configuration when CI will use newer versions of tox and pip (tested for pip 7.1.2 and tox 2.3.1)
pip install -e "git+https://github.com/openstack/fuel-web.git#egg=nailgun&subdirectory=nailgun"