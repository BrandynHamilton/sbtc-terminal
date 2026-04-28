# sBTC Terminal

A multi-signature wallet and payment system for [sBTC](https://www.stacks.co/sbtc) on the [Stacks](https://www.stacks.co/) blockchain. Built with Clarity smart contracts and a Python backend, sBTC Terminal enables secure collaborative custody and transfer of sBTC tokens through configurable multi-sig governance.

---

## Overview

sBTC Terminal provides:

- **Multi-signature vault** -- A shared custody contract where multiple owners must approve transactions before sBTC is released. Configurable signature thresholds (up to 10 owners).
- **Smart wallet** -- A lightweight 3-of-N multi-sig wallet with a simpler propose/approve flow.
- **sBTC payments** -- A thin wrapper for direct sBTC token transfers.
- **DID/KYC service** (planned) -- A backend identity verification layer.

All contracts interact with the official sBTC testnet token at `SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-token`.

---

## Project Structure

```
sbtc_terminal/
├── backend/
│   ├── sbtc_terminal/          # Python backend (WIP)
│   │   ├── __init__.py
│   │   └── core.py
│   ├── did/                    # DID / KYC verification service (WIP)
│   │   └── app/
│   │       └── kyc_server.py
│   ├── pyproject.toml          # Python 3.13+, project metadata
│   ├── Dockerfile
│   └── docker-compose.yml
├── contracts/
│   ├── clarinet/               # Development sandbox (vault + smart-wallet + payment)
│   ├── project/                # Standalone vault project
│   ├── project2/               # Skeleton project (dependencies only)
│   ├── project3/               # Standalone payment contract (Clarity v3)
│   └── sBTC-Vault/             # Production-ready vault v8 (testnet deployed)
├── frontend/                   # Frontend application (WIP)
├── .env
├── .gitignore
└── README.md
```

---

## Smart Contracts

### sBTC Vault (v8) -- `contracts/sBTC-Vault/`

The flagship contract. A multi-signature vault for sBTC with separated sign and execute phases.

**Key features:**
- Initialize with up to 10 wallet owners and a configurable signature threshold
- Propose sBTC transfers specifying recipient and amount
- Owners sign proposals independently
- Execute transactions once the signature threshold is met
- Owner list and proposal state are queryable on-chain
- Direct sBTC payments via `pay-with-sbtc`

**Workflow:**
1. `initialize-wallet` -- Set owners and required signature count
2. `propose-transaction` -- An owner proposes an sBTC transfer
3. `sign-proposal` -- Owners sign the proposal
4. `execute-transaction` -- Anyone can trigger execution once enough signatures exist

**Public functions:**

| Function | Description |
|----------|-------------|
| `initialize-wallet(owners, min-sigs)` | Set up vault owners and threshold |
| `propose-transaction(to, amount)` | Create a new transfer proposal |
| `sign-proposal(proposal-id)` | Add a signature to a proposal |
| `execute-transaction(proposal-id)` | Execute a fully-signed proposal |
| `pay-with-sbtc(amount, recipient)` | Direct sBTC transfer (no multi-sig) |

**Read-only functions:**

| Function | Description |
|----------|-------------|
| `get-proposal(id)` | Full proposal details |
| `get-proposal-amount(id)` | Proposal transfer amount |
| `get-proposal-signatures(id)` | List of signers |
| `get-proposal-executed-status(id)` | Whether proposal has been executed |
| `get-owners()` | List of vault owners |
| `get-required-signatures()` | Current signature threshold |
| `get-next-proposal-id()` | Next auto-incremented proposal ID |

### Smart Wallet -- `contracts/clarinet/contracts/smart-wallet.clar`

A simpler multi-sig wallet for exactly 3 signers with a configurable threshold (1-3). Uses user-supplied transaction IDs and deletes proposals after execution.

### sBTC Payment -- `contracts/clarinet/contracts/sbtc-payment.clar`

A minimal wrapper around the SIP-010 `transfer` function for direct sBTC payments.

---

## Dependencies

All contracts depend on the official sBTC protocol contracts (fetched from Stacks testnet):

| Contract | Purpose |
|----------|---------|
| `sbtc-token` | SIP-010 fungible token (sBTC) |
| `sbtc-registry` | Protocol state, roles, and signer management |
| `sbtc-deposit` | Deposit processing and sBTC minting |

---

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) (Stacks/Clarity development tool)
- [Python 3.13+](https://www.python.org/) (for the backend)
- [Node.js](https://nodejs.org/) (for running contract tests)
- [Docker](https://www.docker.com/) (optional, for containerized backend)

### Running Contracts Locally

```bash
# Navigate to the vault project
cd contracts/sBTC-Vault

# Start the Clarinet console (devnet)
clarinet console

# Initialize the wallet with one owner
(contract-call? .sbtc-vault-v8 initialize-wallet (list tx-sender) u1)

# Propose a transaction
(contract-call? .sbtc-vault-v8 propose-transaction 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG u1000)

# Sign the proposal
(contract-call? .sbtc-vault-v8 sign-proposal u0)

# Execute the transaction
(contract-call? .sbtc-vault-v8 execute-transaction u0)
```

### Deploying to Testnet

```bash
cd contracts/sBTC-Vault

# Generate a testnet deployment plan
clarinet deployments generate --testnet

# Apply the deployment
clarinet deployments apply -p deployments/default.testnet-plan.yaml
```

### Running Tests

```bash
cd contracts/sBTC-Vault

# Install dependencies
npm install

# Run tests
npm test

# Run tests with coverage
npm run test:report
```

### Backend Setup

```bash
cd backend

# Create a virtual environment
python -m venv .venv

# Activate the virtual environment
# Linux/macOS:
source .venv/bin/activate
# Windows:
.venv\Scripts\activate

# Install dependencies
pip install -e .
```

---

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| `u1` | `ERR-NOT-OWNER` | Caller is not an authorized vault owner |
| `u2` | `ERR-INSUFFICIENT-SIGNATURES` | Not enough signatures to execute |
| `u3` | `ERR-PROPOSAL-NOT-FOUND` | Proposal ID does not exist |
| `u4` | `ERR-ALREADY-SIGNED` | Owner has already signed this proposal |
| `u5` | `ERR-TRANSACTION-ALREADY-EXECUTED` | Proposal was already executed |
| `u6` | `ERR-TRANSACTION-FAILED` | sBTC transfer failed |

---

## Tech Stack

- **Smart Contracts**: [Clarity](https://docs.stacks.co/clarity/) (v2/v3) on Stacks
- **Development Tooling**: [Clarinet](https://github.com/hirosystems/clarinet)
- **Testing**: [Vitest](https://vitest.dev/) + [Clarinet SDK](https://github.com/hirosystems/clarinet)
- **Backend**: Python 3.13+
- **Token Standard**: [SIP-010](https://github.com/stacksgov/sips/blob/main/sips/sip-010/sip-010-fungible-token-standard.md) (sBTC)

---

## License

This project is open-source and available under the [MIT License](LICENSE).
