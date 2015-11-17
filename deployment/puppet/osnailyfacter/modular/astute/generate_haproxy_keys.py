"""
This module contain class which could create SSL keys, certificate requests
based on those keys and self-sign those requests
"""

from OpenSSL import crypto

class SSL(object):
    """ This class implements logic related to certificates """

    def __init__(self, privateKey=None, publicKey=None, certReq=None,
            certificate=None):
        """
        Set instance initial data

        Args: privateKey - private key for instanse
              publicKey  - public key for instance
              certReq    - certificate request for instance
              certificate - certificate itself for instance
        Returns: None
        """
        # privateKey stores public key too, it just named so for convenience
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.certReq = certReq
        self.certificate = certificate
        self.keytype = crypto.TYPE_RSA
        self.digest = "sha256"
        self.bits = 2048
        self.extensions = {}

    def createKeys(self, keytype=None, bits=None):
        """
        Creates keypair.

        Args: keytype - one of types, RSA or DSA
              bits    - how many bits to use in key
        Returns: keypair with private/public keys
        """
        if not keytype: keytype = self.keytype
        if not bits: bits = self.bits
        keypair = crypto.PKey()
        keypair.generate_key(keytype, bits)
        self.privateKey = keypair
        # someone could ask why we don't create self.publicKey here - it's
        # just because pyOpenSSL doesn't have such ability by default and I
        # don't want to do it by trick
        return keypair

    def createCertRequest(self, keypair=None, digest=None, **cname):
        """
        Creates certificate request.

        Args: keypair - keypair with private/public keys to use for signing
              digest  - digest method for signing
              **cname - assume hash with values for placing in certificate CN,
                        like:
                            C - Country name
                            ST - State name
                            L - Locality name
                            O - Organization name
                            OU - Organization unit name
                            CN - Common name
                            emailAddress - email address
        Returns: certificate request
        """
        if not keypair: keypair = self.privateKey
        if not digest: digest = self.digest
        req = crypto.X509Req()
        subj = req.get_subject()

        # RFC2818 recommend us to place CN into SAN
        rdn =  cname.get("CN", False)
        san = ["DNS:" + rdn if rdn else False]
        # RFC2818 recommend us to place email into SAN too
        email = cname.pop("emailAddress", False)
        san.append("email:" + email if email else False)
        if san:
            self.extensions["subjectAltName"] = crypto.X509Extension(
                    "subjectAltName", critical=False,
                    value=','.join([a for a in san if a]))

        for k,v in cname.items():
            setattr(subj, k, v)

        req.set_pubkey(keypair)
        req.sign(keypair, digest)
        self.certReq = req
        self.publicKey = req.get_pubkey()
        return req

    def createCertificate(self, req=None, issuerCert=None, issuerKey=None,
            serial=0, validity=(0, 60*60*24*365*10), digest=None,
            extensions=None):
        """
        Creates certificate.

        Args: req - certificate request to sign
              issuerCert    - issuer certificate. In case of self-signed
                              certificates it can be equal to req for sign
              issuerKey     - issuer private key
              serial        - serial number for certificate
              validity      - tuple with 2 values:
                validityBefore - time (relative to now) from which certificate
                                 will be accepted
                validityAfter  - time (relative to now) upon which certificate
                                 will be accepted
              digest        - digest method for signing
              extensions    - hash with x509v3 extensions in X509Extension
                              objects as a values

        Returns: certificate itself
        """
        if not req: req = self.certReq
        if not issuerCert: issuerCert = self.certReq
        if not issuerKey: issuerKey = self.privateKey
        if not digest: digest = self.digest
        if not extensions: extensions = self.extensions
        notBefore, notAfter = validity
        cert = crypto.X509()
        cert.set_serial_number(serial)
        cert.gmtime_adj_notBefore(notBefore)
        cert.gmtime_adj_notAfter(notAfter)
        cert.set_issuer(issuerCert.get_subject())
        cert.set_subject(req.get_subject())
        cert.set_pubkey(req.get_pubkey())
        if extensions: cert.add_extensions(extensions.values())
        cert.sign(issuerKey, digest)
        self.certificate = cert
        return cert

    def createSelfSignedCertificate(self, **cname):
        """
        Creates new self-signed certificate.

        Args: **cname - assume hash with values for placing in certificate CN,
                        like:
                            C - Country name
                            ST - State name
                            L - Locality name
                            O - Organization name
                            OU - Organization unit name
                            CN - Common name
                            emailAddress - email address
        Returns: certificate itself
        """
        self.createKeys()
        self.createCertRequest(**cname)
        self.createCertificate()

    def savePKeyToFile(self, filename, keypair=None):
        """
        Saves private/public keypair to a file.

        Args: filename - path to file in which private key will be stored
              keypair  - PKey object with private/public keys
        Returns: None
        """
        if not keypair: keypair = self.privateKey
        with open(filename, 'w') as fkey:
            fkey.write(crypto.dump_privatekey(crypto.FILETYPE_PEM,
                keypair).decode('utf-8'))

    def saveCertToFile(self, filename, certificate=None):
        """
        Saves certificate to a file.

        Args: filename    - path to file in which certificate will be stored
              certificate - X509 object with certificate
        Returns: None
        """
        if not certificate: certificate = self.certificate
        with open(filename, 'w') as fcert:
            fcert.write(crypto.dump_certificate(crypto.FILETYPE_PEM,
                certificate).decode('utf-8'))

    def saveAllToFile(self, filename, keypair=None, certificate=None):
        """
        Saves both private key and certificate to one file.

        Args: filename    - path to file in which data will be stored
              keypair     - PKey object with private/public keys
              certificate - X509 object with certificate
        Returns: None
        """
        if not keypair: keypair = self.privateKey
        if not certificate: certificate = self.certificate
        with open(filename, 'w') as fpem:
            fpem.write(crypto.dump_certificate(crypto.FILETYPE_PEM,
                certificate).decode('utf-8'))
            fpem.write(crypto.dump_privatekey(crypto.FILETYPE_PEM,
                keypair).decode('utf-8'))

if __name__ == '__main__':
    import argparse
    import yaml
    import os
    parser = argparse.ArgumentParser()
    parser.add_argument('-j', '--json', required=False, help='json for process')
    parser.add_argument('-i', '--id', required=False, help='cluster id')
    parser.add_argument('-h', '--host', required=False, help='hostname')
    parser.add_argument('-o', '--outname', required=False, help='service name')
    parser.add_argument('-p', '--path', required=False, help='cert path')
    parser.add_argument('-t', '--type', required=False, help='out type')

    def createcert(cname, basedir, endpointtype, service):
        """
        Creates certificate and save it to file.

        Args: cname        - common name
              basedir      - directory to save certificate into
              endpointtype - type of endpoint (affect target filename only)
              service      - service name (affect target filename only)
        Returns: None
        """
         ssl_data = SSL()
         ssl_data.createSelfSignedCertificate(**cname)
         functions = {'saveCertToFile':'crt',
                      'savePKeyToFile':'key',
                      'saveAllToFile':'pem'}
         for function,ext in functions.items():
             func = getattr(ssl_data, function)
             func(filename='%s/%s_%s.%s' % (basedir, endpointtype,
                 service, ext))


    data = yaml.safe_load(parser.parse_args().json)
    basedir = '/var/lib/fuel/keys/%s/haproxy' % data['cluster_id']
    if not data:
        path = parser.parse_args().path
        cluster_id = parser.parse_args().id
        sname = parser.parse_args().outname
        basedir = '%s/%s/%s' % (path, cluster_id, sname)
    if not os.path.exists(basedir):
        os.makedirs(basedir)

    if data:
        for service in data['services']:
            for endpointtype in data['services'][service]:
                for hostname in data['services'][service][endpointtype]:
                    print('service: %s, endpoint: %s, hostname: %s' % (
                        service, endpointtype,
                        data['services'][service][endpointtype]['hostname']))
                    cname = {'C':'US',
                        'ST':'California',
                        'L':'Mountain View',
                        'O':'Mirantis',
                        'OU':'Mirantis Deploy Team',
                        'CN':data['services'][service][endpointtype]['hostname'],
                        'emailAddress':'root@fuel.local'}
                    createcert(cname, basedir, endpointtype, service)
    else:
        cname = {'C':'US',
            'ST':'California',
            'L':'Mountain View',
            'O':'Mirantis',
            'OU':'Mirantis Deploy Team',
            'CN':parser.parse_args().host,
            'emailAddress':'root@fuel.local'}
        createcert(cname, basedir, parser.parse_args().type, sname)
