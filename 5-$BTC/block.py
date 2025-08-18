import json
import hashlib
import datetime
import time


class Block:
    def __init__(self, index, transactions, previous_hash, merkle_root, nonce, timestamp = None):
        self.index : int = index
        self.transactions : list = transactions
        self.timestamp : float = timestamp if timestamp is not None else time.time()
        self.previous_hash : str = previous_hash
        self.merkle_root: str = merkle_root
        self.hash : str = None
        self.nonce : int = nonce

    def format_timestamp(self) -> str:
        return datetime.datetime.fromtimestamp(self.timestamp).strftime('%Y-%m-%d %H:%M:%S')

    def compute_hash(self) -> str:
        block = {
            'index': self.index,
            'timestamp': self.format_timestamp(),
            'previous_hash': self.previous_hash,
            'merkle_root': self.merkle_root, 
            'nonce': self.nonce,
        }
        block_string = json.dumps(block, sort_keys=True).encode()
        return hashlib.sha256(block_string).hexdigest()
    
    def to_dict(self) -> dict[str, any]:
        block = {
            'index': self.index,
            'transactions': self.transactions,
            'timestamp': self.format_timestamp(),
            'previous_hash': self.previous_hash,
            'hash': self.hash,
            'merkle_root': self.merkle_root, 
            'nonce': self.nonce,
        }
        return block