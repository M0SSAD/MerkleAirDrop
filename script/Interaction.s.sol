// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IToken} from "src/Token.sol";
import {IMerkleAirDrop} from "src/MerkleAirDrop.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract ClaimAirDrop is Script {
    error __ClaimAirdropScipt_InvalidSignatureLength();

    address public constant CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // The first user on the merkle tree
    uint256 public constant CLAIMING_AMOUNT = 25 * 1e18;
    bytes32 PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public proof = [PROOF_ONE, PROOF_TWO];
    bytes private SIGNATURE = hex"7397ca678c3fe25c19c261e0ecb26fcf6b5cf31f170060d4e9ef5b61763e96920281fc8b28efea23e48e6173ad661a3dc23f5df0cc452464993e316abe0a24bd1c";
    
    function claimAirDrop(address merkleAirdrop) public {
        IMerkleAirDrop airdrop = IMerkleAirDrop(merkleAirdrop);
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        airdrop.claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, proof, v, r, s);
        vm.stopBroadcast();
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        if(sig.length != 65) {
            revert __ClaimAirdropScipt_InvalidSignatureLength();
        }
        assembly{
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
    
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirDrop", block.chainid);
        uint256 bal = IToken(IToken(IMerkleAirDrop(mostRecentlyDeployed).getTokenAddress())).balanceOf(CLAIMING_ADDRESS);
        console.log("User Balance Claiming:", bal / 1e18);
        if(IMerkleAirDrop(mostRecentlyDeployed).isClaimed(CLAIMING_ADDRESS)) {
            console.log("User Already Has Claimed Their Airdrop");
            return;
        }
        claimAirDrop(mostRecentlyDeployed);
    }

}



