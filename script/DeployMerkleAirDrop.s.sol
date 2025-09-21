// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "src/Token.sol";
import {MerkleAirDrop} from "src/MerkleAirDrop.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirDrop is Script {

    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public constant AIRDROP_AMOUNT = 25 * 1e18;
    uint256 public constant TOTAL_AIRDROP = 100 * 1e18;

    
    function deployMerkleAirdrop() public returns (Token _token, MerkleAirDrop _merkleAirDrop) {
        vm.startBroadcast(msg.sender);
        console.log("Deploying Merkle Airdrop Contracts...");
        Token token = new Token(msg.sender);
        MerkleAirDrop merkleAirDrop = new MerkleAirDrop(
            IERC20(token),
            msg.sender,
            ROOT
        );
        token.mint(address(merkleAirDrop), TOTAL_AIRDROP);
        vm.stopBroadcast();

        console.log("Token Deployed To:", address(token));
        console.log("MerkleAirDrop Deployed With Balance Of ", TOTAL_AIRDROP / 1e18, " Tokens At:", address(merkleAirDrop));
        console.log("Deployment Done!");
        return (token, merkleAirDrop);
    }

    function run() external returns (Token _token, MerkleAirDrop _merkleAirDrop) {
        return deployMerkleAirdrop();
    }
}