import xmlrpclib


class CobblerClient(xmlrpclib.Server):
    def __init__(self, host):
        end_point = self.cobbler_end_point(host)
        #noinspection PyCallByClass
        #noinspection PyTypeChecker
        xmlrpclib.Server.__init__(self, end_point)

    def cobbler_end_point(self, host):
        return 'http://%s/cobbler_api' % host

    def modify_system_args(self, system_id, token, **kwargs):
        for k, v in kwargs.iteritems():
            self.modify_system(system_id, k, str(v), token)
