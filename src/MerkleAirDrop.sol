//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title MerkleAirDrop
 * @author Mossad ElMahgob
 * @notice This contract is an educational example of how to implement a Merkle Airdrop.
 * I created this contract whilst learning about Merkle Trees and Airdrops.
 */

contract MerkleAirDrop is Ownable, EIP712 {
    ////////////
    // Errors //
    ////////////
    error MerkleAirDrop_InvalidMerkleProof();
    error MerkleAirDrop_AlreadyClaimed();
    error MerkleAirDrop_InvalidSignature();

    ///////////////////////
    // Type Declarations //
    ///////////////////////
    using SafeERC20 for IERC20;
    struct Airdrop{
        address account;
        uint256 amount;
    }
    
    /////////////////////
    // State Variables //
    /////////////////////
    IERC20 public token;
    bytes32 public merkleRoot;
    
    mapping(address => bool) private hasClaimed;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    ////////////
    // Events //
    ////////////
    event Claimed(address indexed account, uint256 amount);

    ///////////////
    // Functions //
    ///////////////
    constructor(IERC20 _token, address owner, bytes32 _merkleRoot) Ownable(owner) EIP712("MerkleAirDrop", "1") {
        token = _token;
        merkleRoot = _merkleRoot;
    }

    ////////////////////////
    // External Functions //
    ////////////////////////

    /**
     * @notice This Function Is Used To Claim The Airdrop.
     * @param account The Address Of The Account Claiming The Airdrop, So someone can pay for your gas.
     * @param amount The Amount Of Tokens To Claim.
     * @param merkleProof The Merkle Proof To Verify The Claim.
     */
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) external {
        if(hasClaimed[account]) {
            revert MerkleAirDrop_AlreadyClaimed();
        }
        // Checking the signature.
        if(!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirDrop_InvalidSignature();
        }
        // Calculating the leaf node (hash of (account, amount)), Double hashing to avoid second preimage attacks.
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if(!MerkleProof.verify(merkleProof, merkleRoot, leaf)) {
            revert MerkleAirDrop_InvalidMerkleProof();
        }
        hasClaimed[account] = true;
        emit Claimed(account, amount);
        token.safeTransfer(account, amount);
    }

    // These Functions I Implemented To Simulate The Modularity Of Big DeFi Protocols, I Will Try To
    // Implement Governance Systems And Other Modular Functionalities In Future Contracts.
    /**
     * @notice This Function Is Used To Change The Airdrop Token.
     * @param _token The Address Of The New Token To Be Airdropped.
     */
    function setTokenAddress(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    /**
     * @notice This Function Is Used To Change the Merkle Root.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    ////////////////////////
    // Internal Functions //
    ////////////////////////

    // This function is used to verify that the signer of the message is the account that has the right to claim the airdrop
    // by using tryRecover from ECDSA library to recover the address from the signature and compare it to the account address.
    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
        (address actualSigner, , ) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }

    //////////////////////
    // Getter Functions //
    //////////////////////
    /**
     * @notice This Function Is Used To Get The Address Of The Token Being Airdropped.
     */
    function getTokenAddress() external view  returns (address) {
        return address(token);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    // This function Is used to get the digest of the signed message by encoding the Message type Hash
    // ,Which is the hash of the struct and the struct members, with the struct values. And that is the digest.
    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    MESSAGE_TYPEHASH,
                    Airdrop({account: account, amount: amount})
                )
            )
        );
    }

    function isClaimed(address account) external view returns (bool) {
        return hasClaimed[account];
    }
}

interface IMerkleAirDrop {
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) external;
    function getMessageHash(address account, uint256 amount) external view returns (bytes32);
    function isClaimed(address account) external view returns (bool);
    function getMerkleRoot() external view returns (bytes32);
    function getTokenAddress() external view returns (address);
}