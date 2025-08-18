import time
import hashlib
import requests
import json
from block import Block
from urllib.parse import urlparse
import datetime

class Blockchain:
    def __init__(self):
        self.pending_transactions: list[dict[str, any]] = []
        self.chain : list[Block] = []
        self.nodes: set[str] = set()
        self.difficulty: int = 4

        self.create_genesis()


    def create_genesis(self) -> None:
        merkle_root = self.build_merkle_root([])
        genesis_block : Block = Block(
            index=0, 
            transactions=[], 
            previous_hash="1", 
            merkle_root=merkle_root,
            nonce=100
        )
        genesis_block.hash = genesis_block.compute_hash()
        self.chain.append(genesis_block)


    @property
    def last_block(self) -> Block:
        return self.chain[-1]


    def new_transaction(self, sender, recipient, amount) -> int:
        self.pending_transactions.append({
            'sender': sender,
            'recipient': recipient,
            'amount': amount,
        })
        return self.last_block.index + 1


    def proof_of_work(self, block: Block) -> Block:
        block.nonce = 0
        computed_hash = block.compute_hash()
        while not self.is_hash_valid(computed_hash):
            block.nonce += 1
            computed_hash = block.compute_hash()
        
        block.hash = computed_hash
        return block


    def is_hash_valid(self, hash: str) -> bool:
        return hash[:self.difficulty] == '0' * self.difficulty

    def add_block(self, block) -> bool:
        if block.previous_hash != self.last_block.compute_hash():
            return False

        if not self.is_hash_valid(block.hash):
            return False
            
        if block.hash != block.compute_hash():
            return False

        self.chain.append(block)
        self.pending_transactions = []
        return True
    
    def register_node(self, address: str) -> None:
        parsed_url = urlparse(address)
        if parsed_url.netloc:
            self.nodes.add(parsed_url.netloc)
        elif parsed_url.path:
            self.nodes.add(parsed_url.path)
        else:
            raise ValueError('URL tidak valid')


    # <======================== Konsensus ========================>
    def valid_chain(self, chain: list[dict[str, any]]) -> bool:
        last_block_dict = chain[0]
        current_index = 1

        while current_index < len(chain):
            block_dict = chain[current_index]
            
            temp_last_block = Block(
                index=last_block_dict['index'],
                transactions=last_block_dict['transactions'],
                previous_hash=last_block_dict['previous_hash'],
                merkle_root=last_block_dict['merkle_root'],
                nonce=last_block_dict['nonce'],
                timestamp=datetime.datetime.strptime(last_block_dict['timestamp'], '%Y-%m-%d %H:%M:%S').timestamp()
            )
            if block_dict['previous_hash'] != temp_last_block.compute_hash():
                return False

            if not self.is_hash_valid(block_dict['hash']):
                return False
                
            temp_block = Block(
                index=block_dict['index'],
                transactions=block_dict['transactions'],
                previous_hash=block_dict['previous_hash'],
                merkle_root=block_dict['merkle_root'],
                nonce=block_dict['nonce'],
                timestamp=datetime.datetime.strptime(block_dict['timestamp'], '%Y-%m-%d %H:%M:%S').timestamp()
            )
            if block_dict['hash'] != temp_block.compute_hash():
                return False

            last_block_dict = block_dict
            current_index += 1

        return True
    
    
    # Konsensus
    def resolve_conflicts(self) -> bool:
        neighbours = self.nodes
        new_chain_objects = None
        max_length = len(self.chain)

        for node in neighbours:
            try:
                response = requests.get(f'http://{node}/chain', timeout=5)

                if response.status_code == 200:
                    length = response.json()['length']
                    chain_data = response.json()['chain']

                    if length > max_length and self.valid_chain(chain_data):
                        max_length = length
                        
                        temp_chain_objects = []
                        for block_data in chain_data:
                            ts_float = datetime.datetime.strptime(block_data['timestamp'], '%Y-%m-%d %H:%M:%S').timestamp()
                            block = Block(
                                index=block_data['index'],
                                transactions=block_data['transactions'],
                                timestamp=ts_float,
                                previous_hash=block_data['previous_hash'],
                                merkle_root=block_data['merkle_root'],
                                nonce=block_data['nonce']
                            )
                            block.hash = block.compute_hash()
                            temp_chain_objects.append(block)
                        new_chain_objects = temp_chain_objects

            except requests.exceptions.RequestException as e:
                continue

        # Return transactions into pending list
        if new_chain_objects:
            new_chain_transactions = set()
            for block in new_chain_objects:
                for tx in block.transactions:
                    new_chain_transactions.add(json.dumps(tx, sort_keys=True))

            for block in self.chain:
                for tx in block.transactions:
                    tx_string = json.dumps(tx, sort_keys=True)
                    if tx_string not in new_chain_transactions:
                        if tx.get('sender') != '0':
                            self.pending_transactions.append(tx)
            
            self.chain = new_chain_objects
            return True

        return False
    
    @staticmethod
    def build_merkle_root(transactions: list[dict[str, any]]) -> str:
        if not transactions:
            return '0' * 64

        tx_hashes = []
        for tx in transactions:
            tx_string = json.dumps(tx, sort_keys=True).encode()
            tx_hashes.append(hashlib.sha256(tx_string).hexdigest())

        while len(tx_hashes) > 1:
            if len(tx_hashes) % 2 != 0:
                tx_hashes.append(tx_hashes[-1])

            next_level_hashes = []
            for i in range(0, len(tx_hashes), 2):
                pair_hash_string = (tx_hashes[i] + tx_hashes[i+1]).encode()
                next_level_hashes.append(hashlib.sha256(pair_hash_string).hexdigest())
            
            tx_hashes = next_level_hashes
        return tx_hashes[0]