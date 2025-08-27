import requests
import json
import os
import platform
import time


def clear_screen():
    command = 'cls' if platform.system() == 'Windows' else 'clear'
    os.system(command)

def wait_for_enter():
    input("\nPress Enter to continue...")

def print_menu():
    """Prints the main menu of the CLI client."""
    print("====== Blockchain Network CLI ======")
    print("1. Mine a New Block")
    print("2. Display Full Chain")
    print("3. Add a New Transaction")
    print("4. Display Transaction Pool")
    print("5. Register New Nodes")
    print("6. List Registered Nodes")
    print("7. Register All Nodes")
    print("8. Resolve Conflicts (Sync)")
    print("9. Set PoW Difficulty")
    print("10. Clear Screen")
    print("0. Exit")

def handle_response(response: requests.Response):
    if response.status_code >= 200 and response.status_code < 300:
        print("\nSuccess!")
        print(json.dumps(response.json(), indent=2))
    else:
        print(f"\n[!] Error: Received status code {response.status_code}")
        try:
            print(json.dumps(response.json(), indent=2))
        except json.JSONDecodeError:
            print(response.text)


def handle_mine():
    # start = time.time()
    try:
        port = input("Enter node port: ")
        url = f"http://127.0.0.1:{port}/mine"
        response = requests.get(url, timeout=10000)     # long timeouts for high difficulty
        handle_response(response)
    except ValueError:
        print("\n[!] Invalid port. Please enter a number.")
    except requests.exceptions.RequestException as e:
        print(f"\n[!] Connection Error: Could not connect to node at port {port}. Is it running?")
    # print("Time: ", time.time() - start, "ms")
def handle_view_chain():
    try:
        port = input("Enter node port: ")
        url = f"http://127.0.0.1:{port}/chain"
        response = requests.get(url, timeout=10)
        handle_response(response)
    except ValueError:
        print("\n[!] Invalid port. Please enter a number.")
    except requests.exceptions.RequestException as e:
        print(f"\n[!] Connection Error: Could not connect to node at port {port}. Is it running?")


def handle_new_transaction():
    try:
        port = input("Enter node port: ")
        sender = input("Enter sender: ")
        recipient = input("Enter recipient: ")
        amount = float(input("Enter amount: "))
        
        url = f"http://127.0.0.1:{port}/transaction/new"
        payload = {'sender': sender, 'recipient': recipient, 'amount': amount}
        response = requests.post(url, json=payload, timeout=10)
        handle_response(response)
    except ValueError:
        print("\n[!] Invalid input. Port and amount must be numbers.")
    except requests.exceptions.RequestException as e:
        print(f"\n[!] Connection Error: Could not connect to node at port {port}. Is it running?")


def handle_transaction_pool():
    """Fetches and displays the list of pending transactions from a node."""
    try:
        port = input("Enter target node port: ")
        url = f"http://127.0.0.1:{port}/transaction/pool"
        response = requests.get(url, timeout=10)
        handle_response(response)
    except ValueError:
        print("\n[!] Invalid port. Please enter a number.")
    except requests.exceptions.RequestException as e:
        print(f"\n[!] Connection Error: Could not connect to node at port {port}. Is it running?")
        

def handle_register_nodes():
    try:
        port = input("Enter node port (the node that will register others): ")
        num_nodes = int(input("How many nodes to register? "))
        
        node_addresses = []
        for i in range(num_nodes):
            node_port = input(f"Enter port for node #{i+1}: ")
            node_addresses.append(f"http://127.0.0.1:{node_port}")
            
        url = f"http://127.0.0.1:{port}/nodes/register"
        payload = {'nodes': node_addresses}
        response = requests.post(url, json=payload, timeout=10)
        handle_response(response)
    except ValueError:
        print("\n[!] Invalid input. Port and number of nodes must be integers.")
    except requests.exceptions.RequestException as e:
        print(f"\n[!] Connection Error: Could not connect to node at port {port}. Is it running?")

def handle_automatic_register():
    try:
        num_nodes = int(input("How many nodes to register? "))
        if num_nodes < 2:
            print("\n[!] You need at least 2 nodes to form a network.")
            return

        all_ports = []
        for i in range(num_nodes):
            port = input(f"Enter port for node #{i+1}: ")
            all_ports.append(port)
        
        for target_port in all_ports:
            peers = []
            for peer_port in all_ports:
                if peer_port != target_port:
                    peers.append(f"http://127.0.0.1:{peer_port}")

            url = f"http://127.0.0.1:{target_port}/nodes/register"
            payload = {'nodes': peers}
            
            print(f"Registering {len(peers)} peers with node at port {target_port}...")
            
            try:
                response = requests.post(url, json=payload, timeout=10)
                if response.status_code == 201:
                    print(f"Success.")
                else:
                    print(f"[!] Error with node {target_port}: {response.json().get('message', 'Unknown error')}")
            except requests.exceptions.RequestException:
                print(f"[!] Connection Error: Could not connect to node at port {target_port}.")
        
    except ValueError:
        print("\n[!] Invalid input. Number of nodes and ports must be integers.")


def handle_resolve_conflicts():
    try:
        port = input("Enter node port (the node to sync): ")
        url = f"http://127.0.0.1:{port}/nodes/resolve"
        response = requests.get(url, timeout=30)
        handle_response(response)
    except ValueError:
        print("\n[!] Invalid port. Please enter a number.")
    except requests.exceptions.RequestException as e:
        print(f"\n[!] Connection Error: Could not connect to node at port {port}. Is it running?")
        

def handle_list_nodes():
    try:
        port = input("Enter node port: ")
        url = f"http://127.0.0.1:{port}/nodes/list"
        response = requests.get(url, timeout=10)
        handle_response(response)
    except ValueError:
        print("\n[!] Invalid port. Please enter a number.")
    except requests.exceptions.RequestException as e:
        print(f"\n[!] Connection Error: Could not connect to node at port {port}. Is it running?")


def handle_set_difficulty():
    try:
        port = input("Enter node port: ")
        difficulty = int(input("Enter new difficulty level (e.g., 4): "))
        
        url = f"http://127.0.0.1:{port}/difficulty"
        payload = {'difficulty': difficulty}
        response = requests.post(url, json=payload, timeout=10)
        handle_response(response)
    except ValueError:
        print("\n[!] Invalid input. Port and difficulty must be integers.")
    except requests.exceptions.RequestException as e:
        print(f"\n[!] Connection Error: Could not connect to node at port {port}. Is it running?")
        

def main():
    """Main function to run the CLI loop."""
    clear_screen()
    while True:
        print_menu()
        choice = input("Select an option: ")
        print()

        if choice == '1':
            handle_mine()
        elif choice == '2':
            handle_view_chain()
        elif choice == '3':
            handle_new_transaction()
        elif choice == '4':
            handle_transaction_pool()
        elif choice == '5':
            handle_register_nodes()
        elif choice == '6':
            handle_list_nodes()
        elif choice == '7':
            handle_automatic_register()
        elif choice == '8':
            handle_resolve_conflicts()
        elif choice == '9':
            handle_set_difficulty()
        elif choice == '10':
            clear_screen()
            continue
        elif choice == '0':
            print("Exiting...")
            break
        else:
            print("\nInvalid option, please try again.")
        
        wait_for_enter()

if __name__ == '__main__':
    main()