from os.path import dirname, join
from unittest import TestCase

from pytezos import pytezos, Contract, ContractInterface, MichelsonRuntimeError


shell = 'http://tzero_flextesa:20000'
admin  = 'tz1TZeroxuxJXiZen3myriSiKMNnegAahPf6'
issuer = 'tz1R3nRTHbRotdSt5TE63Xc897zjjSmxUKPU'
investor_1 = 'tz1ii1iPX8HWbgms6vPCFSbgYAKmJcWZu3F8'
investor_2 = 'tz1ii2ivhPA5TXdoQr1bU3kscexbm97a6qDy'
total_supply = 100000
default_balances = {issuer: 50000, investor_1: 30000, investor_2: 20000}

initial_storage = {
    'admins': [admin],
    'issuer': issuer,
    'symbol': 'TZROP',
    'description': 'tZERO Preferred, series A',
    'total_supply': total_supply,
    'issuance_finished': False,
    'allowances': {},
    'balances': default_balances,
    'registry': "KT1QNkdkfvydieMTwDhuhstRFfPi8r2NsHCs",
    'rules': "KT1WfGEz9qe7Y7QeEKh3RAqCUGtQNhQguK8d",
    'paused': False,
}


def failwith(error):
    return error.exception.args[0]['with']['string']

def failwith_fa12(error):
    args = error.exception.args[0]['with']['args']
    message = args[0]['string']
    amounts = args[1]['args'][0]['int'], args[1]['args'][1]['int']
    return message, amounts

def failwith_fa12_allowance(error):
    args = error.exception.args[0]['with']['args']
    message = args[0]['string']
    amount = args[1]['int']
    return message, amount

def initial_storage_with(**kwargs):
    s = initial_storage.copy()
    for k in kwargs:
        s[k] = kwargs[k]
    return s

def initial_storage_from(storage, **kwargs):
    s = initial_storage_with(**kwargs)
    s['allowances'] = storage['allowances']
    s['balances'] = storage['balances']
    return s


class TestT0ken(TestCase):

    @classmethod
    def setUpClass(cls):
        cls.contract = ContractInterface.create_from(join(dirname(__file__), '../build/t0ken.tz'), shell=shell)
        cls.registry = Contract.from_file(join(dirname(__file__), '../build/registry.tz'))
        cls.maxDiff = None

    def test_approve(self):
        res = self.contract.approve(spender=investor_2, value=1) \
            .result(storage=initial_storage,
                    source=investor_1)

        big_map_diff = {
            'allowances': {(investor_1, investor_2): 1},
            'balances': default_balances,
        }

        self.assertDictEqual(big_map_diff, res.big_map_diff)

    def test_approve_non_holder(self):
        storage = initial_storage_with(balances={issuer: total_supply})

        res = self.contract.approve(spender=investor_2, value=1) \
            .result(storage=storage,
                    source=investor_1)

        big_map_diff = {
            'allowances': {(investor_1, investor_2): 1},
            'balances': {issuer: total_supply},
        }

        self.assertDictEqual(big_map_diff, res.big_map_diff)

    def test_approve_existing(self):
        storage = initial_storage_with(allowances={(investor_1, investor_2): 5})

        with self.assertRaises(MichelsonRuntimeError) as error:
            res = self.contract.approve(spender=investor_2, value=1) \
                .result(storage=storage,
                        source=investor_1)

        self.assertEqual(('UnsafeAllowanceChange', ('5')), failwith_fa12_allowance(error))

    def test_finish_issuance(self):
        res = self.contract.finishIssuance(None) \
            .result(storage=initial_storage,
                    source=issuer)

        storage=initial_storage_from(res.storage, issuance_finished=True)
        self.assertDictEqual(storage, res.storage)

    def test_finish_issuance_when_already_finished(self):
        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.finishIssuance(None) \
                .result(storage=initial_storage_with(issuance_finished=True),
                        source=issuer)

        self.assertEqual("NotAllowed", failwith(error))

    def test_finish_issuance_non_issuer(self):
        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.finishIssuance(None) \
                .result(storage=initial_storage,
                        source=admin)

        self.assertEqual("NotAllowed", failwith(error))

    def test_get_allowance(self):
        value = 9
        callback = 'KT1AHErKFaYAayARYUPZF7yjXaGnT8p6AE8C'

        storage = initial_storage_with(allowances={(investor_1, investor_2): value})
        param = {'owner': investor_1, 'spender': investor_2, 'callback': callback}
        res = self.contract.getAllowance(param) \
            .interpret(storage=storage)

        operation = {
            'kind': 'transaction',
            'source': 'KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi',
            'amount': '0',
            'destination': callback,
            'parameters': {'entrypoint': 'default', 'value': {'int': str(value)}}
        }

        self.assertEqual(len(res.operations), 1)
        self.assertDictEqual(operation, res.operations[0])

    def test_get_balance(self):
        callback = 'KT1AHErKFaYAayARYUPZF7yjXaGnT8p6AE8C'

        param = {'owner': investor_1, 'callback': callback}
        res = self.contract.getBalance(param) \
            .interpret(storage=initial_storage)

        operation = {
            'kind': 'transaction',
            'source': 'KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi',
            'amount': '0',
            'destination': callback,
            'parameters': {'entrypoint': 'default', 'value': {'int': str(initial_storage['balances'][investor_1])}}
        }

        self.assertEqual(len(res.operations), 1)
        self.assertDictEqual(operation, res.operations[0])

    def test_total_supply(self):
        callback = 'KT1AHErKFaYAayARYUPZF7yjXaGnT8p6AE8C'

        res = self.contract.getTotalSupply(None, callback) \
                .interpret(storage=initial_storage)

        operation = {
            'kind': 'transaction',
            'source': 'KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi',
            'amount': '0',
            'destination': callback,
            'parameters': {'entrypoint': 'default', 'value': {'int': str(total_supply)}}
        }

        self.assertEqual(len(res.operations), 1)
        self.assertDictEqual(operation, res.operations[0])

    def test_issue_tokens(self):
        res = self.contract.issueTokens(99) \
            .result(storage=initial_storage,
                    source=issuer)

        storage=initial_storage_from(res.storage, total_supply=100099)
        self.assertDictEqual(storage, res.storage)

    def test_issue_tokens_non_issuer(self):
        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.issueTokens(99) \
                .result(storage=initial_storage,
                        source=admin)

        self.assertEqual("NotAllowed", failwith(error))

    def test_issue_tokens_after_finish(self):
        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.issueTokens(99) \
                .result(storage=initial_storage_with(issuance_finished=True),
                        source=issuer)

        self.assertEqual("NotAllowed", failwith(error))

    def test_set_rules(self):
        rules = 'KT1AHErKFaYAayARYUPZF7yjXaGnT8p6AE8C'

        res = self.contract.setRules(rules) \
            .result(storage=initial_storage,
                    source=admin)

        storage=initial_storage_from(res.storage, rules=rules)
        self.assertDictEqual(storage, res.storage)

    def test_set_rules_non_admin(self):
        rules = 'KT1AHErKFaYAayARYUPZF7yjXaGnT8p6AE8C'

        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.setRules(rules) \
                .result(storage=initial_storage,
                        source=issuer)

        self.assertEqual("NotAllowed", failwith(error))

    def test_transfer(self):
        balances = initial_storage['balances']
        param = {'from': investor_1, 'to': investor_2, 'value': 1}

        res = self.contract.transfer(param) \
            .interpret(storage=initial_storage,
                    source=investor_1)

        big_map_diff = {
            'balances': {
                issuer: 50000,
                investor_1: 29999,
                investor_2: 20001,
            }
        }
        op = {
            'validateAccounts': {
                'addresses': [investor_1, investor_2],
                'balances': [balances[investor_1], balances[investor_2]],
                'issuance': False,
                'values': [1, initial_storage['total_supply']],
                'callback': initial_storage['rules'] + '%validateRules',
            }
        }

        params = res.operations[0]['parameters']
        res_op = self.registry.parameter.decode(params)

        self.assertDictEqual(op, res_op)
        self.assertDictEqual(big_map_diff, res.big_map_diff)

    def test_transfer_insufficient_funds(self):
        param = {'from': investor_1, 'to': investor_2, 'value': 11}
        storage = initial_storage_with(
            balances={investor_1: 10},
        )

        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.transfer(param) \
                .result(storage=storage,
                        source=investor_1)

        self.assertEqual(('NotEnoughBalance', ('11', '10')), failwith_fa12(error))

    def test_transfer_issuance(self):
        balances = initial_storage['balances']
        param = {'from': issuer, 'to': investor_1, 'value': 1}

        res = self.contract.transfer(param) \
            .interpret(storage=initial_storage,
                    source=issuer)

        big_map_diff = {
            'balances': {
                issuer: 49999,
                investor_1: 30001,
                investor_2: 20000
            }
        }
        op = {
            'validateAccounts': {
                'addresses': [issuer, investor_1],
                'balances': [balances[issuer], balances[investor_1]],
                'issuance': True,
                'values': [1, initial_storage['total_supply']],
                'callback': initial_storage['rules'] + '%validateRules',
            }
        }

        params = res.operations[0]['parameters']
        res_op = self.registry.parameter.decode(params)

        self.assertDictEqual(op, res_op)
        self.assertDictEqual(big_map_diff, res.big_map_diff)

    def test_transfer_exact_allowance(self):
        balances = initial_storage['balances']
        initiator = 'tz1ii3iWF9vQVqkPDHHii13ZqtYvjayqiAzk'
        param = {'from': investor_1, 'to': investor_2, 'value': 1}
        storage = initial_storage_with(
            allowances={(investor_1, initiator): 1},
        )

        res = self.contract.transfer(param) \
            .interpret(storage=storage,
                    source=initiator)

        big_map_diff = {
            'allowances': {
                (investor_1, initiator): 0,
            },
            'balances': {
                issuer: 50000,
                investor_1: 29999,
                investor_2: 20001,
            }
        }
        op = {
            'validateAccounts': {
                'addresses': [investor_1, investor_2],
                'balances': [balances[investor_1], balances[investor_2]],
                'issuance': False,
                'values': [1, initial_storage['total_supply']],
                'callback': initial_storage['rules'] + '%validateRules',
            }
        }

        params = res.operations[0]['parameters']
        res_op = self.registry.parameter.decode(params)

        self.assertDictEqual(big_map_diff, res.big_map_diff)
        self.assertDictEqual(op, res_op)

    def test_transfer_within_allowance(self):
        initiator = 'tz1ii3iWF9vQVqkPDHHii13ZqtYvjayqiAzk'
        storage = initial_storage_with(
            balances={investor_1: 10},
            allowances={(investor_1, initiator): 50},
        )
        param = {'from': investor_1, 'to': investor_2, 'value': 5}

        res = self.contract.transfer(param) \
            .interpret(storage=storage, source=initiator)

        big_map_diff = {
            'allowances': {
                (investor_1, initiator): 45,
            },
            'balances': {
                investor_1: 5,
                investor_2: 5,
            }
        }

        self.assertDictEqual(big_map_diff, res.big_map_diff)

    def test_transfer_exceeds_allowance(self):
        initiator = 'tz1ii3iWF9vQVqkPDHHii13ZqtYvjayqiAzk'
        param = {'from': investor_1, 'to': investor_2, 'value': 5}
        storage = initial_storage_with(
            balances={investor_1: 10},
            allowances={(investor_1, initiator): 4},
        )

        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.transfer(param) \
                .result(storage=storage, source=initiator)

        self.assertEqual(('NotEnoughAllowance', ('5', '4')), failwith_fa12(error))

    def test_transfer_no_allowance(self):
        initiator = 'tz1ii3iWF9vQVqkPDHHii13ZqtYvjayqiAzk'
        param = {'from': investor_1, 'to': investor_2, 'value': 1}
        storage = initial_storage_with(
            balances={investor_1: 10},
        )

        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.transfer(param) \
                .result(storage=storage, source=initiator)

        self.assertEqual(('NotEnoughAllowance', ('1', '0')), failwith_fa12(error))

    def test_transfer_override_invalid_registry(self):
        param = {'from': investor_1, 'to': investor_2, 'value': 1}

        with self.assertRaises(MichelsonRuntimeError) as error:
            self.contract.transferOverride(param) \
            .result(storage=initial_storage, source=admin)

        self.assertEqual("InvalidRegistry", failwith(error))

    def test_transfer_override(self):
        callback = 'KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi'
        param = {'from': investor_1, 'to': investor_2, 'value': 1}

        res = self.contract.transferOverride(param) \
            .interpret(storage=initial_storage, source=admin)

        big_map_diff = {
            'balances': {
                issuer: 50000,
                investor_1: 29999,
                investor_2: 20001,
            }
        }
        operation = {
            'kind': 'transaction',
            'source': 'KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi',
            'amount': '0',
            'destination': 'KT1QNkdkfvydieMTwDhuhstRFfPi8r2NsHCs',
            'parameters': {
                'entrypoint': 'validateAccount',
                'value': {
                    'string': 'tz1ii2ivhPA5TXdoQr1bU3kscexbm97a6qDy'
                }
            }
        }
        self.assertEqual(len(res.operations), 1)
        self.assertDictEqual(operation, res.operations[0])
        self.assertDictEqual(big_map_diff, res.big_map_diff)

    def test_transfer_override_non_admin(self):
        initiator = 'tz1ii3iWF9vQVqkPDHHii13ZqtYvjayqiAzk'
        param = {'from': investor_1, 'to': investor_2, 'value': 1}

        with self.assertRaises(MichelsonRuntimeError) as error:
            res = self.contract.transferOverride(param) \
                .result(storage=initial_storage, source=initiator)

        self.assertEqual("NotAllowed", failwith(error))
