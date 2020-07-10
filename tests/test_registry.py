from os.path import dirname, join
from copy import deepcopy
from unittest import TestCase

from pytezos import pytezos, ContractInterface, MichelsonRuntimeError


shell = 'http://tzero_flextesa:20000'
admin     = 'tz1TZeroxuxJXiZen3myriSiKMNnegAahPf6'
issuer    = 'tz1R3nRTHbRotdSt5TE63Xc897zjjSmxUKPU'
custodian = 'tz1cc1cG3c6cpsScweeTP1jod6Ueeoash13E'
custodial = 'tz1aa1aAP6tDrq8Bm4TJBxcNBsD7jXg7g3Gr'
broker    = 'tz1bb1bSF9Y1WLjV5BK5HyXmMFjCGXvqDFdY'
investor  = 'tz1ii1iPX8HWbgms6vPCFSbgYAKmJcWZu3F8'
extrinsic = 'tz1ee1eyF3wLnXLe2T9KJTwb81m4i2dxP9w5'
unknown   = 'tz1QwEsCvVBs2owozESqSc3qEbUJLzBsY46P'

""" The order of these matter
When originating a contract, the keys of a mapping _must_ be ordered or the origination will fail.
The same holds true, currently, when specifying storage within PyTest.
"""
initial_storage = {
    issuer:    {'parent': admin,     'role': 2, 'frozen': False, 'domicile': 'US', 'accreditation': None},
    admin:     {'parent': admin,     'role': 1, 'frozen': False, 'domicile': 'US', 'accreditation': None},
    custodial: {'parent': custodian, 'role': 4, 'frozen': False, 'domicile': 'US', 'accreditation': None},
    broker:    {'parent': custodian, 'role': 5, 'frozen': False, 'domicile': 'US', 'accreditation': None},
    custodian: {'parent': admin,     'role': 3, 'frozen': False, 'domicile': 'US', 'accreditation': None},
    extrinsic: {'parent': admin,     'role': 7, 'frozen': False, 'domicile': 'US', 'accreditation': None},
    investor:  {'parent': broker,    'role': 6, 'frozen': False, 'domicile': 'US', 'accreditation': None},
}

valid_roles = [
    (1, admin), (2, admin), (3, admin), (4, custodian), (5, custodian), (6, broker), (7, admin),
]

invalid_roles = [
    (1, issuer),    (2, issuer),    (3, issuer),    (4, issuer),    (5, issuer),    (6, issuer),    (7, issuer),
    (1, custodian), (2, custodian), (3, custodian), (4, broker),    (5, custodial), (3, custodian), (7, custodian),
    (1, custodial), (2, custodial), (3, custodial), (4, investor),  (5, broker),    (6, custodial), (7, custodial),
    (1, broker),    (2, broker),    (3, broker),    (4, extrinsic), (5, investor),  (6, investor),  (7, broker),
    (1, investor),  (2, investor),  (3, investor),                  (5, extrinsic), (6, extrinsic), (7, investor),
    (1, extrinsic), (2, extrinsic), (3, extrinsic),                                                 (7, extrinsic),
]

def failwith(error):
    return error.exception.args[0]['with']['string']

def initial_storage_with(**kwargs):
    s = initial_storage.copy()
    for k in kwargs:
        s[k] = kwargs[k]
    return s

def account_param_to_account(param, parent):
    account = param.copy()
    account['parent'] = parent
    del(account['address'])
    return account

class TestCompliance(TestCase):

    @classmethod
    def setUpClass(cls):
        cls.contract = ContractInterface.create_from(join(dirname(__file__), '../build/registry.tz'), shell=shell)
        cls.maxDiff = None

    def test_append(self):
        address = 'tz1ii2ivhPA5TXdoQr1bU3kscexbm97a6qDy'
        account_param = {
            'address': address,
            'role': 0,
            'frozen': False,
            'domicile': 'US',
            'accreditation': 1588895859,
        }

        for role, source in valid_roles:
            with self.subTest():
                account_param['role'] = role
                res = self.contract.append(account_param) \
                    .result(storage=initial_storage,
                            source=source)

                account = account_param_to_account(account_param, source)
                big_map_diff = initial_storage.copy()
                big_map_diff[address] = account

                self.assertDictEqual(big_map_diff, res.big_map_diff)

    def test_append_invalid_role(self):
        account_param = {
            'address': 'tz1ii2ivhPA5TXdoQr1bU3kscexbm97a6qDy',
            'role': 0,
            'frozen': False,
            'domicile': 'US',
            'accreditation': 0,
        }

        for role, source in invalid_roles:
            with self.subTest():
                account_param['role'] = role
                with self.assertRaises(MichelsonRuntimeError) as error:
                    self.contract.append(account_param) \
                        .result(storage=initial_storage,
                                source=source)

                self.assertEqual("InvalidRole", failwith(error))

    def test_append_invalid_source(self):
        account_param = {
            'address': 'tz1ii2ivhPA5TXdoQr1bU3kscexbm97a6qDy',
            'role': 6,
            'frozen': False,
            'domicile': 'US',
            'accreditation': 1588895859,
        }

        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.append(account_param) \
                .result(storage=initial_storage,
                        source=unknown)

        self.assertEqual("InvalidAddress", failwith(error))


    def test_append_update(self):
        account_param = {
            'address': investor,
            'role': 6,
            'frozen': False,
            'domicile': 'JP',
            'accreditation': 1588895859,
        }

        res = self.contract.append(account_param) \
            .result(storage=initial_storage,
                    source=broker)

        account = account_param_to_account(account_param, broker)
        big_map_diff = initial_storage.copy()
        big_map_diff[investor] = account

        self.assertDictEqual(big_map_diff, res.big_map_diff)

    def test_append_update_invalid_role(self):
        account_param = {
            'address': investor,
            'role': 5,
            'frozen': False,
            'domicile': 'US',
            'accreditation': None,
        }

        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.append(account_param) \
                .result(storage=initial_storage,
                        source=broker)

        self.assertEqual("InvalidRole", failwith(error))

    def test_append_update_invalid_parent(self):
        account_param = {
            'address': investor,
            'role': 6,
            'frozen': False,
            'domicile': 'JP',
            'accreditation': 1588895859,
        }

        for source in [issuer,  admin, custodial, custodian, extrinsic, investor]:
            with self.subTest():
                with self.assertRaises(MichelsonRuntimeError) as error:
                    self.contract.append(account_param) \
                        .result(storage=initial_storage,
                                source=source)

                self.assertEqual("InvalidRole", failwith(error))

    def test_append_update_unknown(self):
        account_param = {
            'address': investor,
            'role': 6,
            'frozen': False,
            'domicile': 'JP',
            'accreditation': 1588895859,
        }

        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.append(account_param) \
                .result(storage=initial_storage,
                        source=unknown)

        self.assertEqual("InvalidAddress", failwith(error))

    def test_validate_account(self):
        for address in [admin, issuer, custodian, custodial, broker, investor, extrinsic]:
            with self.subTest():
                self.contract.validateAccount(address).result(storage=initial_storage)

    def test_validate_account_unknown(self):
        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.validateAccount(unknown).result(storage=initial_storage)

        self.assertEqual("InvalidAddress", failwith(error))
