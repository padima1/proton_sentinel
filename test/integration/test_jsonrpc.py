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
    genesis_hash = u'00000e1728b630fd83aecbc51546c7915fffb7d3c897b5fd8c4b14043070b7f0'
    for line in config_text.split("\n"):
        if line.startswith('testnet=1'):
            network = 'testnet'
            is_testnet = True
            genesis_hash = u'0000000f350d9039575f6446584f4ae4317bed76aae26ef1f2381ff73f7cd68d'

    creds = ProtonConfig.get_rpc_creds(config_text, network)
    protond = ProtonDaemon(**creds)
    assert protond.rpc_command is not None

    assert hasattr(protond, 'rpc_connection')

    # Proton testnet block 0 hash == 0000000f350d9039575f6446584f4ae4317bed76aae26ef1f2381ff73f7cd68d
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
