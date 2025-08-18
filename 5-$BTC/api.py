import random
from uuid import uuid4
from flask import Flask, jsonify, request
import requests
import datetime

from blockchain import Blockchain, Block

app = Flask(__name__)

node_identifier = str(uuid4()).replace('-', '')
blockchain = Blockchain()


@app.route('/mine', methods=['GET'])
def mine() -> tuple[dict[str, any], int]:
    last_block = blockchain.last_block

    blockchain.new_transaction(
        sender="0",
        recipient=node_identifier,
        amount=round(random.uniform(0.1, 5.0), 4),
    )
    
    pending_txs = list(blockchain.pending_transactions)
    merkle_root = Blockchain.build_merkle_root(pending_txs)

    previous_hash = last_block.compute_hash()
    
    candidate_block = Block(
        index=last_block.index + 1,
        transactions=pending_txs,
        previous_hash=previous_hash,
        merkle_root=merkle_root,
        nonce=0 
    )
    
    mined_block = blockchain.proof_of_work(candidate_block)
    blockchain.add_block(mined_block)

    # ==== Broadcast New Block
    broadcast_resps = []
    for node_address in blockchain.nodes:
        node_resps = {"address": node_address}
        try:
            app.logger.info(f"Mencoba mengirim blok ke {node_address}...")
            res = requests.post(f'http://{node_address}/nodes/receive_block', json=mined_block.to_dict())
            try:
                node_resps["response"] = res.json()
            except requests.exceptions.JSONDecodeError:
                node_resps["response"] = res.text
        except requests.exceptions.RequestException as e:
            app.logger.error(f"Failed to propagate to {node_address}: {e}")

        broadcast_resps.append(node_resps)
    response = {
        'message': "Blok baru berhasil ditambang dan disebarkan!",
        'block': mined_block.to_dict(),
        'nodes_responses': broadcast_resps,
    }
    return jsonify(response), 200


@app.route('/chain', methods=['GET'])
def full_chain() -> tuple[dict[str, any], int]:
    response = {
        'chain': [block.to_dict() for block in blockchain.chain],
        'length': len(blockchain.chain),
    }
    return jsonify(response), 200


@app.route('/difficulty', methods=['POST'])
def set_difficulty() -> tuple[dict[str, any], int]:
    values = request.get_json()
    if not values:
        return jsonify({'message': 'Error: Mohon sediakan data'}), 400

    difficulty_level = values.get('difficulty')
    if difficulty_level is None or not isinstance(difficulty_level, int):
        return jsonify({'message': 'Error: Mohon sediakan nilai "difficulty" dalam bentuk integer'}), 400

    # Update atribut difficulty di objek blockchain
    blockchain.difficulty = difficulty_level

    response = {
        'message': 'Tingkat kesulitan berhasil diubah.',
        'new_difficulty': blockchain.difficulty
    }
    return jsonify(response), 200

# ==================== TRANSACTIONS ==================================
@app.route('/transaction/new', methods=['POST'])
def new_transaction() -> tuple[dict[str, str], int]:
    values = request.get_json()
    required = ['sender', 'recipient', 'amount']
    if not all(k in values for k in required):
        return jsonify({'message': 'Data tidak lengkap'}), 400

    index = blockchain.new_transaction(values['sender'], values['recipient'], values['amount'])
    response = {'message': f'Transaksi akan ditambahkan ke Blok {index}'}
    return jsonify(response), 201


@app.route('/transaction/pending', methods=['GET'])
def get_pending_transactions():
    """Returns the list of pending transactions."""
    return jsonify(blockchain.pending_transactions), 200


# ============================= NODES =================================================
@app.route('/nodes/register', methods=['POST'])
def register_nodes() -> tuple[dict[str, any], int]:
    values = request.get_json()

    nodes = values.get('nodes')
    if nodes is None:
        return jsonify({'message': 'Error: Mohon sediakan daftar node yang valid'}), 400

    for node in nodes:
        blockchain.register_node(node)

    response = {
        'message': 'Node baru telah ditambahkan',
        'total_nodes': list(blockchain.nodes),
    }
    return jsonify(response), 201


@app.route('/nodes/resolve', methods=['GET'])
def consensus() -> tuple[dict[str, any], int]:
    replaced = blockchain.resolve_conflicts()

    if replaced:
        response = {
            'message': 'Rantai kami telah diganti dengan yang otoritatif',
            'new_chain': [block.to_dict() for block in blockchain.chain]
        }
    else:
        response = {
            'message': 'Rantai kami sudah yang paling otoritatif',
            'chain': [block.to_dict() for block in blockchain.chain]
        }

    return jsonify(response), 200


@app.route('/nodes/list', methods=['GET'])
def get_nodes() -> tuple[dict[str, any], int]:
    """Mengembalikan daftar semua node yang terdaftar."""
    nodes = list(blockchain.nodes)
    response = {
        'message': 'Menampilkan semua node terdaftar',
        'nodes': nodes
    }
    return jsonify(response), 200


@app.route('/nodes/receive_block', methods=['POST'])
def receive_block() -> tuple[dict[str, str], int]:
    app.logger.info("Menerima permintaan di /nodes/receive_block...")
    block_data = request.get_json()
    if not block_data:
        return jsonify({'message': 'Error: Tidak ada data blok'}), 400

    last_block = blockchain.last_block
    
    if block_data['previous_hash'] == last_block.compute_hash():
        
        received_block = Block(
            index=block_data['index'], 
            transactions=block_data['transactions'],
            previous_hash=block_data['previous_hash'],
            merkle_root=block_data['merkle_root'],
            nonce=block_data['nonce'],
            timestamp=datetime.datetime.strptime(block_data['timestamp'], '%Y-%m-%d %H:%M:%S').timestamp(),
        )
        
        if block_data['hash'] != received_block.compute_hash():
            return jsonify({'message': 'Blok ditolak: Hash tidak cocok (integritas gagal)'}), 400

        if not blockchain.is_hash_valid(block_data['hash']):
            return jsonify({'message': 'Blok ditolak: Proof of Work tidak valid'}), 400
        
        # VALID
        received_block.hash = block_data['hash']
        blockchain.add_block(received_block)
        return jsonify({'message': 'Blok baru diterima dan ditambahkan'}), 201
    
    # Konsensus (longest chain)
    else:
        is_chain_replaced = blockchain.resolve_conflicts()
        if is_chain_replaced:
            return jsonify({'message': 'Konflik terdeteksi. Rantai diganti.'}), 200
        else:
            return jsonify({'message': 'Blok diterima dari fork pendek, rantai tidak diganti.'}), 200


if __name__ == '__main__':
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument('-p', '--port', default=5000, type=int, help='port to listen on')
    args = parser.parse_args()
    port = args.port

    app.run(host='0.0.0.0', port=port)