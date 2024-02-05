export type TrustedHintRegistryDeployment = {
  chainId: number
  registry: string
  type: "proxy" | "logic"
  name?: string
  description?: string
  rpcUrl?: string
}

export const deployments: TrustedHintRegistryDeployment[] = [
  { chainId: 11155111, registry: '0x2b219C6e76A8Df00Aa90155620078d56a6e3f26c', type: "proxy", name: 'sepolia' },
  { chainId: 11155111, registry: '0x2A8Cab520A06Dd679ef59f12d5DB19E78322D385', type: "logic", name: 'sepolia' },
]

export const TRUSTED_HINT_REGISTRY_ABI = [
  {
    "inputs": [],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "previousAdmin",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "newAdmin",
        "type": "address"
      }
    ],
    "name": "AdminChanged",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "beacon",
        "type": "address"
      }
    ],
    "name": "BeaconUpgraded",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [],
    "name": "EIP712DomainChanged",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "namespace",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "list",
        "type": "bytes32"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "newDelegate",
        "type": "address"
      }
    ],
    "name": "HintListDelegateAdded",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "namespace",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "list",
        "type": "bytes32"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "oldDelegate",
        "type": "address"
      }
    ],
    "name": "HintListDelegateRemoved",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "namespace",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "list",
        "type": "bytes32"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      }
    ],
    "name": "HintListOwnerChanged",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "namespace",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "list",
        "type": "bytes32"
      },
      {
        "indexed": true,
        "internalType": "bool",
        "name": "revoked",
        "type": "bool"
      }
    ],
    "name": "HintListStatusChanged",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "namespace",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "list",
        "type": "bytes32"
      },
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "key",
        "type": "bytes32"
      },
      {
        "indexed": false,
        "internalType": "bytes32",
        "name": "value",
        "type": "bytes32"
      }
    ],
    "name": "HintValueChanged",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "uint8",
        "name": "version",
        "type": "uint8"
      }
    ],
    "name": "Initialized",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "previousOwner",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      }
    ],
    "name": "OwnershipTransferred",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "Paused",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "Unpaused",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "implementation",
        "type": "address"
      }
    ],
    "name": "Upgraded",
    "type": "event"
  },
  {
    "inputs": [],
    "name": "VERSION_DELIMITER",
    "outputs": [
      {
        "internalType": "string",
        "name": "",
        "type": "string"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "VERSION_MAJOR",
    "outputs": [
      {
        "internalType": "string",
        "name": "",
        "type": "string"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "VERSION_MINOR",
    "outputs": [
      {
        "internalType": "string",
        "name": "",
        "type": "string"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "VERSION_PATCH",
    "outputs": [
      {
        "internalType": "string",
        "name": "",
        "type": "string"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "_delegate",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_untilTimestamp",
        "type": "uint256"
      }
    ],
    "name": "addListDelegate",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "_delegate",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_untilTimestamp",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "_signer",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_signature",
        "type": "bytes"
      }
    ],
    "name": "addListDelegateSigned",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "name": "delegates",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "eip712Domain",
    "outputs": [
      {
        "internalType": "bytes1",
        "name": "fields",
        "type": "bytes1"
      },
      {
        "internalType": "string",
        "name": "name",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "version",
        "type": "string"
      },
      {
        "internalType": "uint256",
        "name": "chainId",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "verifyingContract",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "salt",
        "type": "bytes32"
      },
      {
        "internalType": "uint256[]",
        "name": "extensions",
        "type": "uint256[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_key",
        "type": "bytes32"
      }
    ],
    "name": "getHint",
    "outputs": [
      {
        "internalType": "bytes32",
        "name": "",
        "type": "bytes32"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_key",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_value",
        "type": "bytes32"
      }
    ],
    "name": "getMetadata",
    "outputs": [
      {
        "internalType": "bytes",
        "name": "",
        "type": "bytes"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "_identity",
        "type": "address"
      }
    ],
    "name": "identityIsDelegate",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "_identity",
        "type": "address"
      }
    ],
    "name": "identityIsOwner",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "initialize",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "",
        "type": "bytes32"
      }
    ],
    "name": "metadata",
    "outputs": [
      {
        "internalType": "bytes",
        "name": "",
        "type": "bytes"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "",
        "type": "bytes32"
      }
    ],
    "name": "newOwners",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "name": "nonces",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "pause",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "paused",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "proxiableUUID",
    "outputs": [
      {
        "internalType": "bytes32",
        "name": "",
        "type": "bytes32"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "_delegate",
        "type": "address"
      }
    ],
    "name": "removeListDelegate",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "_delegate",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_signer",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_signature",
        "type": "bytes"
      }
    ],
    "name": "removeListDelegateSigned",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "renounceOwnership",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "",
        "type": "bytes32"
      }
    ],
    "name": "revokedLists",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_key",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_value",
        "type": "bytes32"
      }
    ],
    "name": "setHint",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_key",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_value",
        "type": "bytes32"
      },
      {
        "internalType": "bytes",
        "name": "_metadata",
        "type": "bytes"
      }
    ],
    "name": "setHint",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_key",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_value",
        "type": "bytes32"
      },
      {
        "internalType": "bytes",
        "name": "_metadata",
        "type": "bytes"
      }
    ],
    "name": "setHintDelegated",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_key",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_value",
        "type": "bytes32"
      }
    ],
    "name": "setHintDelegated",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_key",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_value",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "_signer",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_signature",
        "type": "bytes"
      }
    ],
    "name": "setHintDelegatedSigned",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_key",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_value",
        "type": "bytes32"
      },
      {
        "internalType": "bytes",
        "name": "_metadata",
        "type": "bytes"
      },
      {
        "internalType": "address",
        "name": "_signer",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_signature",
        "type": "bytes"
      }
    ],
    "name": "setHintDelegatedSigned",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_key",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_value",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "_signer",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_signature",
        "type": "bytes"
      }
    ],
    "name": "setHintSigned",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_key",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_value",
        "type": "bytes32"
      },
      {
        "internalType": "bytes",
        "name": "_metadata",
        "type": "bytes"
      },
      {
        "internalType": "address",
        "name": "_signer",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_signature",
        "type": "bytes"
      }
    ],
    "name": "setHintSigned",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32[]",
        "name": "_keys",
        "type": "bytes32[]"
      },
      {
        "internalType": "bytes32[]",
        "name": "_values",
        "type": "bytes32[]"
      }
    ],
    "name": "setHints",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32[]",
        "name": "_keys",
        "type": "bytes32[]"
      },
      {
        "internalType": "bytes32[]",
        "name": "_values",
        "type": "bytes32[]"
      },
      {
        "internalType": "bytes[]",
        "name": "_metadata",
        "type": "bytes[]"
      }
    ],
    "name": "setHints",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32[]",
        "name": "_keys",
        "type": "bytes32[]"
      },
      {
        "internalType": "bytes32[]",
        "name": "_values",
        "type": "bytes32[]"
      },
      {
        "internalType": "bytes[]",
        "name": "_metadata",
        "type": "bytes[]"
      }
    ],
    "name": "setHintsDelegated",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32[]",
        "name": "_keys",
        "type": "bytes32[]"
      },
      {
        "internalType": "bytes32[]",
        "name": "_values",
        "type": "bytes32[]"
      }
    ],
    "name": "setHintsDelegated",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32[]",
        "name": "_keys",
        "type": "bytes32[]"
      },
      {
        "internalType": "bytes32[]",
        "name": "_values",
        "type": "bytes32[]"
      },
      {
        "internalType": "bytes[]",
        "name": "_metadata",
        "type": "bytes[]"
      },
      {
        "internalType": "address",
        "name": "_signer",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_signature",
        "type": "bytes"
      }
    ],
    "name": "setHintsDelegatedSigned",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32[]",
        "name": "_keys",
        "type": "bytes32[]"
      },
      {
        "internalType": "bytes32[]",
        "name": "_values",
        "type": "bytes32[]"
      },
      {
        "internalType": "address",
        "name": "_signer",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_signature",
        "type": "bytes"
      }
    ],
    "name": "setHintsDelegatedSigned",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32[]",
        "name": "_keys",
        "type": "bytes32[]"
      },
      {
        "internalType": "bytes32[]",
        "name": "_values",
        "type": "bytes32[]"
      },
      {
        "internalType": "address",
        "name": "_signer",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_signature",
        "type": "bytes"
      }
    ],
    "name": "setHintsSigned",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32[]",
        "name": "_keys",
        "type": "bytes32[]"
      },
      {
        "internalType": "bytes32[]",
        "name": "_values",
        "type": "bytes32[]"
      },
      {
        "internalType": "bytes[]",
        "name": "_metadata",
        "type": "bytes[]"
      },
      {
        "internalType": "address",
        "name": "_signer",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_signature",
        "type": "bytes"
      }
    ],
    "name": "setHintsSigned",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "_newOwner",
        "type": "address"
      }
    ],
    "name": "setListOwner",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "_newOwner",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_signer",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_signature",
        "type": "bytes"
      }
    ],
    "name": "setListOwnerSigned",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bool",
        "name": "_revoked",
        "type": "bool"
      }
    ],
    "name": "setListStatus",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bool",
        "name": "_revoked",
        "type": "bool"
      },
      {
        "internalType": "address",
        "name": "_signer",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_signature",
        "type": "bytes"
      }
    ],
    "name": "setListStatusSigned",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_key",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_value",
        "type": "bytes32"
      },
      {
        "internalType": "bytes",
        "name": "_metadata",
        "type": "bytes"
      }
    ],
    "name": "setMetadata",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_key",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_value",
        "type": "bytes32"
      },
      {
        "internalType": "bytes",
        "name": "_metadata",
        "type": "bytes"
      }
    ],
    "name": "setMetadataDelegated",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_key",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_value",
        "type": "bytes32"
      },
      {
        "internalType": "bytes",
        "name": "_metadata",
        "type": "bytes"
      },
      {
        "internalType": "address",
        "name": "_signer",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_signature",
        "type": "bytes"
      }
    ],
    "name": "setMetadataDelegatedSigned",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_namespace",
        "type": "address"
      },
      {
        "internalType": "bytes32",
        "name": "_list",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_key",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "_value",
        "type": "bytes32"
      },
      {
        "internalType": "bytes",
        "name": "_metadata",
        "type": "bytes"
      },
      {
        "internalType": "address",
        "name": "_signer",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_signature",
        "type": "bytes"
      }
    ],
    "name": "setMetadataSigned",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      }
    ],
    "name": "transferOwnership",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "unpause",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "newImplementation",
        "type": "address"
      }
    ],
    "name": "upgradeTo",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "newImplementation",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "data",
        "type": "bytes"
      }
    ],
    "name": "upgradeToAndCall",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "version",
    "outputs": [
      {
        "internalType": "string",
        "name": "",
        "type": "string"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
] as const;