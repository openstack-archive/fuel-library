from fuel_test.cobbler.vm_test_case import CobblerTestCase

__author__ = 'alan'

import unittest


class MyTestCase(CobblerTestCase):



    def test_something(self):
        master_node = self.nodes().masters[0]
        master_remote = master_node.remote('public', login='root',
                                           password='r00tme')
        self.ci().setup_master_node(master_remote, self.environment().nodes)



if __name__ == '__main__':
    unittest.main()
