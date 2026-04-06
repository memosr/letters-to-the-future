# 📬 Letters to the Future

> **An on-chain message board on Base mainnet — write words that last forever.**

[![Base](https://img.shields.io/badge/Network-Base%20Mainnet-0052FF?style=flat&logo=base&logoColor=white)](https://base.org)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.20-363636?style=flat&logo=solidity)](https://soliditylang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Passing-brightgreen?style=flat&logo=github-actions)](test/LettersToTheFuture.t.sol)

---

## 📸 Screenshots

| Feed | Write a Letter |
|------|---------------|
| *(screenshot)* | *(screenshot)* |

> 🌐 **Live at:** [memosr.github.io/letters-to-the-future](https://memosr.github.io/letters-to-the-future/index.html)

---

## 💌 What is it?

Letters to the Future is a permissionless, on-chain message board deployed on Base mainnet. Anyone with a wallet can write a short message — up to 280 characters — and that message is stored permanently on the blockchain, visible to anyone, forever.

No accounts. No servers. No delete button. Just you, your words, and the chain.

Think of it as a time capsule you drop into the blockchain: a note to strangers, to the future, to yourself.

---

## ⚙️ How it works

1. **Connect wallet** — click "Connect Wallet" and approve with MetaMask or any EIP-1193 wallet on Base mainnet
2. **Write your letter** — compose a message up to 280 characters
3. **Sign the transaction** — one transaction, no ETH cost beyond gas (~fractions of a cent on Base)
4. **It lives on-chain forever** — your message, your address, and timestamp are stored in contract state and emitted as an event — immutable and permanent

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Smart contract | Solidity `^0.8.20` |
| Testing & deployment | [Foundry](https://book.getfoundry.sh/) (forge, cast, anvil) |
| Frontend | Vanilla JS + HTML/CSS (no frameworks) |
| Blockchain library | [ethers.js v6](https://docs.ethers.org/v6/) |
| Network | [Base Mainnet](https://base.org) (chainId 8453) |
| Hosting | GitHub Pages |

---

## 🚀 Local Development

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- A `.env` file with your keys (see below)

### Setup

```bash
git clone https://github.com/memosr/letters-to-the-future.git
cd letters-to-the-future

# Install Foundry dependencies
forge install
```

### Build

```bash
forge build
```

### Test

```bash
forge test
```

Run with verbosity for event traces:

```bash
forge test -vvv
```

### Deploy to Base Mainnet

Create a `.env` file:

```env
PRIVATE_KEY=your_private_key_here
BASESCAN_API_KEY=your_basescan_api_key_here
```

Then deploy and verify:

```bash
forge script script/Deploy.s.sol \
  --rpc-url base \
  --broadcast \
  --verify \
  -vvvv
```

---

## 📄 Contract Details

| Field | Value |
|-------|-------|
| **Address** | [`0x526a3e3ace6f5ef40ec8ddb8e87995f9a8271000`](https://basescan.org/address/0x526a3e3ace6f5ef40ec8ddb8e87995f9a8271000) |
| **Network** | Base Mainnet (chainId 8453) |
| **Max message length** | 280 bytes |

### Functions

```solidity
// Write a new message (max 280 bytes, must be non-empty)
function postMessage(string calldata message) external

// Read all messages ever posted
function getMessages() external view returns (Message[] memory)

// Get the total number of messages posted
function getMessageCount() external view returns (uint256)
```

### Events

```solidity
event MessagePosted(
    address indexed sender,
    uint256 indexed index,
    uint96  timestamp,
    string  text
);
```

### Errors

```solidity
error EmptyMessage();                              // message is zero bytes
error MessageTooLong(uint256 length, uint256 max); // message exceeds 280 bytes
```

### Message struct

```solidity
struct Message {
    address sender;     // wallet that posted the message
    uint96  timestamp;  // block.timestamp at post time (packed into one slot with sender)
    string  text;       // the message content
}
```

---

## 🤝 Contributing

Contributions, ideas, and letters are welcome.

1. Fork the repo
2. Create a feature branch (`git checkout -b feat/my-idea`)
3. Make your changes and add tests
4. Run `forge test` — all tests must pass
5. Open a pull request

Please keep PRs focused. If you're changing contract logic, include tests that cover the new behavior.

---

## 📜 License

[MIT](LICENSE) — free to use, fork, and build upon.

---

<p align="center">
  Made with ☕ and a belief that some words deserve to last.
</p>
