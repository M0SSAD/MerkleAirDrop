# Merkle Airdrop Project

Hey, this is my take on building a Merkle Airdrop in Solidity. I wanted to learn how Merkle trees work for stuff like efficient airdrops, where you don't have to store a huge list of addresses on-chain. It's super cool because it saves gas and keeps things secure. I followed some ideas from Cyfrin's course, but I tweaked things to make it my own, like adding owner functions to update the token or root if needed. I hardcoded some values just to keep it simple for practice—no big deal, it's all for learning.

What I did was create a system where eligible users can claim tokens using a Merkle proof and a signature (via EIP-712), so even if someone else pays the gas, it's still secure. I learned a ton about hashing, proofs, and signatures—stuff like how to avoid replay attacks and why double-hashing leaves prevents certain hacks.

## What I Learned Overall

- **Merkle Trees Basics**: They're like a binary tree of hashes. You hash pairs of data (leaves) up to a root hash. To prove something's in the tree, you just need the path (proof) and hash your way up to match the root. No need to check the whole list—saves a lot of gas!
- **EIP-712 and Signatures**: This was tricky at first. It's for signing structured data so wallets can show readable messages. I learned how to hash the message with domain separators to prevent replays across chains.
- **ECDSA Verification**: Using OpenZeppelin's library to recover the signer's address from v, r, s. Cool how assembly code splits the signature bytes efficiently.
- **Scripts and Automation**: Foundry scripts are awesome for deploying and interacting. I copied some from Cyfrin but understood how they generate JSON inputs/outputs for the Merkle tree.
- **Security Stuff**: Things like checking if already claimed with a mapping, validating proofs with OpenZeppelin's MerkleProof.verify, and ensuring signatures match the claimant to avoid unauthorized claims.
- **Challenges**: Debugging the signature splitting in assembly was fun, offsets like add(sig, 32) make sense now for memory loading. Also, learned why we use safeTransfer for ERC20 to handle non standard tokens.


## The Contracts and Scripts

### MerkleAirDrop.sol

This is the main contract. In the constructor, I set the token (an ERC20) and the Merkle root (from the generated tree). I inherited from Ownable for owner-only functions and EIP712 for typed signing.

The claim function:

- It checks if the address has already claimed using a mapping (hasClaimed).
- Verifies the signature with _isValidSignature, which uses ECDSA.tryRecover to get the signer and match it to the account—ensures no one can claim for you without permission.
- Builds the leaf by double-hashing (keccak256(bytes.concat(keccak256(abi.encode(account, amount)))) ) to avoid preimage attacks.
- Uses MerkleProof.verify to check if the proof leads to the root.
- If all good, marks as claimed, emits an event, and transfers tokens with safeTransfer.

I added setTokenAddress and setMerkleRoot for modularity, like in big DeFi protocols. Getter functions to check stuff like token address or if claimed.

 
### DeployMerkleAirDrop.s.sol

Script to deploy everything. It creates the Token, then the MerkleAirDrop with the root and token, then mints 100 tokens to the airdrop contract (for 4 users at 25 each).

I used vm.startBroadcast for real deployments. Logs addresses and balances for easy checking.

### GenerateInput.s.sol

This script (from Cyfrin) generates a JSON input file with whitelisted addresses and amounts. I hardcoded 4 addresses, each getting 25e18 tokens. It builds a JSON with types and values.

Run it first to make input.json, which feeds into the next script.

Learned: How off-chain data prep works for Merkle trees, string manipulation in scripts is handy.

### MakeMerkle.s.sol

Another Cyfrin script that takes input.json, builds the Merkle tree using Murky library, and outputs proofs, root, and leaves in output.json.

It hashes leaves with ltrim64 to clean ABI encoding, then generates proofs. I used this to get my ROOT constant.

### Interaction.s.sol

Script for claiming. Has hardcoded proof, address, amount, and a signature (hex). Splits the signature with assembly (r at +32, s at +64, v at +96 byte 0).

In run(), it gets the latest deployed contract with DevOpsTools, checks balance/claimed, then calls claim.

## How to Run It

1. Run GenerateInput.s.sol to make input.json.
2. Run MakeMerkle.s.sol to get output.json (grab the root for deployment).
3. Deploy with DeployMerkleAirDrop.s.sol.
4. Claim with ClaimAirDrop.s.sol (update sig if needed).

Tested on local Anvil, worked great. Next time, I'd add more tests or a frontend for real users.
