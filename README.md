## Trusted Hint Registry

This repository contains a smart contract for a registry of trusted hints used in decentralized ecosystems based on 
ERC-7506. It provides a standardized on-chain metadata management system aiding in verification of on- and off-chain 
data, like Verifiable Credentials.

### Key Decisions

- Upgradable smart contract using ERC1967 to enable future feature additions and bug fixes.
- General purpose, access-controlled data structure usable by any address for hints.
- Development, testing, and deployment is done via the Foundry toolset.
- The deployments and ABI are provided via an NPM package from this repository.

## Usage

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Deploy

```shell
forge script DeployProxy --rpc-url <your_rpc_url> --private-key <your_private_key> --etherscan-api-key <your_etherscan_key> --verify --optimize --broadcast
```
## Usage in other projects

### Install

```shell
npm i @spherity/trusted-hint-registry
```

### Import

This package provides separate build for CommonJS and ES modules. You can import it in your project like this:

```typescript
import { TRUSTED_HINT_REGISTRY_ABI, deployments } from "@spherity/trusted-hint-registry"
```

In combination with, e.g., [viem](https://viem.sh/), you can use it like this:

```typescript
import { TRUSTED_HINT_REGISTRY_ABI, deployments } from "@spherity/trusted-hint-registry";
import { getContract } from 'viem'

const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(),
})

const sepoliaDeployment = deployments.find(d => d.chainId === 11155111 && d.type === "proxy")
const contract = getContract({
  address: sepoliaDeployment.registry,
  abi: TRUSTED_HINT_REGISTRY_ABI,
  publicClient,
})

const namespace = "0x..."
const list = "0x..."
const key = "0x..."
const hint = await contract.read.getHint(namespace, list, key)
)