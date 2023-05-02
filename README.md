# Cosmos-based Node Ansible Setup 

### NOT FULLY TESTED YET

## Inventory configuration

Inventory define server that script will deploy cosmos node to

Inventory is configured in file `inventory.ini`

This file is gitignored and needed to be created on your own.

## General node configuration



## Software version configuration

Software version configuration is found at `group_vars/all.yml`

Make sure to update them to latest version before proceeding to next step.

## Chain configuration

Chain configuration for mainnet is found at `group_vars/[mainnets or testnets]/[chain nickname].yml`

You must copy yml file of existing chain to a new chain you are deploying

Chain configuration file consist of following sections

### Basic information
* network - nickname for that chain (config file name). FOr example, cosmoshub
* folder - Home of daemon data. For example, .gaiad
* daemon - Command line daemon executable name. For example, gaiad
* chain_id - Formal chain ID of that chain. Usually found on chain's doc or explorers such as https://www.mintscan.io/. For example, cosmoshub-4
* node_version - Node JS version. For example, "v0.11.0" or "v16.16.0"

#### Daemon binary

Daemon binary can be installed from source or prebuilt binary.

**Install from source**

Set `repo` config to daemon's repository URL. For example, https://github.com/cosmos/gaia or https://github.com/tharsis/evmos

**install from prebuilt binary**

Set `binary` config to daemon's binary file URL. For example, https://github.com/evmos/evmos/releases/download/v10.0.0/evmos_10.0.0_Linux_amd64.tar.gz

Moreover, if your binary comes in zip, set `binary_processing` config to `zip`, `gz` or `targz` according to your binary's file extension.

You must choose only one choice

### genesis.json

Set `genesis_processing` to genesis.json file URL. For example, https://github.com/tharsis/mainnet/blob/main/evmos_9001-2/genesis.json.zip?raw=true

Moreover, if your genesis.json comes in zip, set `genesis_processing` config to `zip`, `gz` or `targz` according to your genesis.json's file extension.

### Initial seeds and peers
* seeds - initial seeds of that chain. Usually found in chain's doc. For example, ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:13456
* peers (Optional) - initial peers of that chain who operate same kind of daemon. Usually found in chain's doc. For example, 0d0f0e4a149b50a96207523a5408611dae2796b6@198.199.82.109:26656

Initial seeds and peers can contains multiple values separated by comma. For example,

```
eaa763cde89fcf5a8fe44274a5ee3ce24bce2c5b@64.227.18.169:26656,0d0f0e4a149b50a96207523a5408611dae2796b6@198.199.82.109:26656,c2870ce12cfb08c4ff66c9ad7c49533d2bd8d412@178.170.47.171:26656"
```

### Snapshot (Optional)
snapshot_hour and snapshot_minute control which time snapshot be taken each day.

Recommended config:

* snapshot_hour = 2
* snapshot_minute = 0

Recommended config will schedule snapshot to run at 2:00 AM everyday

### KMS / HSM (Optional)
Specify server IP address that you want to deploy your tmkms HSM controller to

* kms_address - tmkms server IP address.

## How to run plackbook

```
ansible-playbook main.yml --extra-vars "target=cosmos_theta_main"
```

## Node installation flow

Run entrypoint playbook in this order

* main.yml - Install initial software (prepare) and install
* kms.yml - Install HSM integration using tmkms yubihsm (Optional)

### Node types
* Main - Main validator node. Doesn't expose any RPC / gRPC / API ports.
* Backup - Validator backup node to be used in case main node is down
* Relayer - RPC and API endpoint

### Role prepare
* apt update && aot upgrade
* Install node_exporter
* Install promtail
* Setup firewall
	* Allow node_exporter port (9100)
	* Allow SSH port (22)
	* Deny any other ports
	* Enable firewall
* Install cosmos softwares
	* Install build-essential
	* Install go
	* Install cosmovisor
	* Update .profile to load installed tools
	* Update .profile to set DAEMON_NAME and DAEMON_HOME environment variable

### Role node_install
* Clone daemon repository
* Run `make install` to build and install daemon into go bin folder 
* Or download daemon binary and copy it into go bin folder

### Role node_initialize
* Remove daemon folder (Ex: .gaiad) if it exists
* Initialize daemon (`gaiad init {{ node_name }} --chain-id {{ chain_id }} --home {{ folder }} -o`)
* Download config.toml file (Optional, config_file, mostly not used)
* Download app.toml file (Optional, app_file, mostly not used)
* Download addrbook.json file (Optional, addrbook_file, mostly not used)
* Update minimum-gas-prices (Optional, minimum_gas_price)
* Download genesis.json
* Set daemon's chain ID
* Set daemon's p2p port

### Role node_configure
* Get public_ip
* Update external_address config with public IP and port
* Update ports in config.toml to use custom port prefix
* Adjust maximum inbound and outbound peers to 80 and 60
* Update ports in app.toml to use custom port prefix
* Adjust pruning settings
* Adjust indexer settings (main and backup only)
* Enable RPC, API server and Swagger (relayer only)
* Enable prometheus in config.toml
* Config KMS (Optional, kms_address)

### Role node_launch
* Update persistent_peers
* Update seeds
* Allow prometheus port on firewall
* Allow p2p port on firewall
* Create cosmovisor directories
	* .gaiad/cosmovisor/genesis/bin
	* .gaiad/cosmovisor/upgrades
* Copy daemon binary to cosmovisor (.gaiad/cosmovisor/genesis/bin)
* Create cosmovisor service file
* Start/Restart cosmovisor service

## Backup and Snapshot flow