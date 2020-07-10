from os.path import dirname, join
from copy import deepcopy
from unittest import TestCase

from pytezos import pytezos, ContractInterface, MichelsonRuntimeError
from pytezos.michelson.converter import michelson_to_micheline
from pytezos.michelson.contract import ContractParameter


shell = 'http://tzero_flextesa:20000'
admin    = 'tz1TZeroxuxJXiZen3myriSiKMNnegAahPf6'
unknown  = 'tz1QwEsCvVBs2owozESqSc3qEbUJLzBsY46P'
registry = 'KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi'
rules    = ['KT1WfGEz9qe7Y7QeEKh3RAqCUGtQNhQguK8d']

accounts = {
    # From
    'parent': 'tz1bb1bSF9Y1WLjV5BK5HyXmMFjCGXvqDFdY',
    'role': 5,
    'frozen': False,
    'domicile': 'US',
    'accreditation': 1588895859,
    # To
    'address_8': 'tz1bb1bSF9Y1WLjV5BK5HyXmMFjCGXvqDFdY',
    'nat_9': 5,
    'bool_7': False,
    'string_6': 'US',
    'nat_5': 1588895859
}

validate_response = {
    'accounts': accounts,
    'addresses': ['tz1ii1iPX8HWbgms6vPCFSbgYAKmJcWZu3F8', 'tz1ii2ivhPA5TXdoQr1bU3kscexbm97a6qDy'],
    'balances': [10, 0],
    'issuance': False,
    'sender': 'KT1QNkdkfvydieMTwDhuhstRFfPi8r2NsHCs',
    'values': [1, 8675309],
}

initial_storage = {
    'admin': admin,
    'registry': registry,
    'rules': rules,
}

rule_type_expr = """
pair (pair (pair (pair %accounts
                         (pair (pair (pair (option %accreditation nat) (string %domicile))
                                     (pair (bool %frozen) (address %parent)))
                               (nat %role))
                         (pair (pair (pair (option %accreditation nat) (string %domicile))
                                     (pair (bool %frozen) (address %parent)))
                               (nat %role)))
                      (pair %addresses address address))
                (pair (pair %balances nat nat) (bool %issuance)))
          (pair (address %sender) (pair %values nat nat))
"""


def failwith(error):
    return error.exception.args[0]['with']['string']

def object_with(o, **kwargs):
    o = deepcopy(o)
    for k in kwargs:
        o[k] = kwargs[k]
    return o

def accounts_with(**kwargs):
    return object_with(accounts, **kwargs)

def validate_response_with(**kwargs):
    return object_with(validate_response, **kwargs)

def initial_storage_with(**kwargs):
    return object_with(initial_storage, **kwargs)


class TestCompliance(TestCase):

    @classmethod
    def setUpClass(cls):
        cls.contract = ContractInterface.create_from(join(dirname(__file__), '../build/rules.tz'), shell=shell)
        cls.rule_param = ContractParameter(michelson_to_micheline(rule_type_expr))
        cls.maxDiff = None

    def test_validate_rules(self):
        res = self.contract.validateRules(validate_response) \
            .interpret(storage=initial_storage,
                        sender=registry)

        self.assertEqual(len(res.operations), 1)
        op = self.rule_param.decode(res.operations[0]['parameters'])
        self.assertDictEqual(op, validate_response)

    #TODO: This test doesn't currently work, although it _does_ work when run in local Flextesa, as well as mainnet.
    #      This is most likely an issue with PyTezos.
    #def test_validate_no_rules(self):
    #    storage = initial_storage_with(rules=[])

    #    res = self.contract.validateRules(validate_response) \
    #        .interpret(storage=storage,
    #                    sender=registry)

    #    self.assertEqual(len(res.operations), 0)

    def test_validate_multiple_rules(self):
        storage = initial_storage_with(rules=['KT1WfGEz9qe7Y7QeEKh3RAqCUGtQNhQguK8d', 'KT1VrL2EcQJKbTkd7g5hrP2QErEoHCg1Gzh8'])

        res = self.contract.validateRules(validate_response) \
            .interpret(storage=storage,
                        sender=registry)

        self.assertEqual(len(res.operations), 2)
        op_1 = self.rule_param.decode(res.operations[0]['parameters'])
        op_2 = self.rule_param.decode(res.operations[0]['parameters'])
        self.assertDictEqual(op_1, validate_response)
        self.assertDictEqual(op_2, validate_response)

    def test_validate_rules_invalid_sender(self):
        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.validateRules(validate_response) \
                .result(storage=initial_storage,
                            sender=unknown)

        self.assertEqual("InvalidSender", failwith(error))

    def test_validate_rules_frozen_grantor(self):
        accounts = accounts_with(frozen=True)
        param = validate_response_with(accounts=accounts)

        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.validateRules(param) \
                .result(storage=initial_storage,
                            sender=registry)

        self.assertEqual("FrozenAccount", failwith(error))

    def test_validate_rules_frozen_receiver(self):
        accounts = accounts_with(bool_7=True)
        param = validate_response_with(accounts=accounts)

        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.validateRules(param) \
                .result(storage=initial_storage,
                            sender=registry)

        self.assertEqual("FrozenAccount", failwith(error))

    def test_validate_rules_frozen_sender_and_receiver(self):
        accounts = accounts_with(frozen=True, bool_7=True)
        param = validate_response_with(accounts=accounts)

        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.validateRules(param) \
                .result(storage=initial_storage,
                            sender=registry)

        self.assertEqual("FrozenAccount", failwith(error))

    def test_set_rules(self):
        rules=['KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi', 'KT1AidDEXDDY6QBPDiR4X8P8WsbUNr1XVNMs']

        res = self.contract.setRules(rules) \
            .result(storage=initial_storage,
                    source=admin)

        self.assertDictEqual(initial_storage_with(rules=rules), res.storage)

    def test_set_rules_empty(self):
        storage = initial_storage_with(rules=[])

        res = self.contract.setRules([]) \
            .result(storage=storage,
                    source=admin)

        self.assertDictEqual(storage, res.storage)

    def test_set_rules_non_admin(self):
        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.setRules([]) \
            .result(storage=initial_storage,
                    source=unknown)

        self.assertEqual("NotAllowed", failwith(error))
