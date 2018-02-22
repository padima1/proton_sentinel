import pytest
import sys
import os
import re
os.environ['SENTINEL_ENV'] = 'test'
os.environ['SENTINEL_CONFIG'] = os.path.normpath(os.path.join(os.path.dirname(__file__), '../test_sentinel.conf'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'lib'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))
import config

from protond import ProtonDaemon
from proton_config import ProtonConfig


def test_protond():
    config_text = ProtonConfig.slurp_config_file(config.proton_conf)
    network = 'mainnet'
    is_testnet = False
    genesis_hash = u'000005e8d240378921a0c3e84933ed2059ab1375304809a33884a86c6d8bf38c'
    for line in config_text.split("\n"):
        if line.startswith('testnet=1'):
            network = 'testnet'
            is_testnet = True
            genesis_hash = u'000005e8d240378921a0c3e84933ed2059ab1375304809a33884a86c6d8bf38c'

    creds = ProtonConfig.get_rpc_creds(config_text, network)
    protond = ProtonDaemon(**creds)
    assert protond.rpc_command is not None

    assert hasattr(protond, 'rpc_connection')

    # Proton testnet block 0 hash == 000005e8d240378921a0c3e84933ed2059ab1375304809a33884a86c6d8bf38c
    # test commands without arguments
    info = protond.rpc_command('getinfo')
    info_keys = [
        'blocks',
        'connections',
        'difficulty',
        'errors',
        'protocolversion',
        'proxy',
        'testnet',
        'timeoffset',
        'version',
    ]
    for key in info_keys:
        assert key in info
    assert info['testnet'] is is_testnet

    # test commands with args
    assert protond.rpc_command('getblockhash', 0) == genesis_hash
