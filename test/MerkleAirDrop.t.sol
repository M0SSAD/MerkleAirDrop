// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "src/Token.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MerkleAirDrop} from "../src/MerkleAirDrop.sol";
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirDrop} from "script/DeployMerkleAirDrop.s.sol";

contract MerkleAirDropTest is Test, ZkSyncChainChecker {
    MerkleAirDrop public merkleAirDrop;
    Token public token;

    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    address user1;
    uint256 user1PrivKey;
    
    address gasPayer = makeAddr("gasPayer"); // a user to claim on behalf of the eligible user

    bytes32 PROOF_OF_USER1_1 = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 PROOF_OF_USER1_2 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF_1 = [PROOF_OF_USER1_1, PROOF_OF_USER1_2];

    function setUp() public {
        if(!isZkSyncChain()) {
            DeployMerkleAirDrop deployer = new DeployMerkleAirDrop();
            (token, merkleAirDrop) = deployer.deployMerkleAirdrop();
        } else {
            token = new Token(address(this));
            merkleAirDrop = new MerkleAirDrop(IERC20(token), address(this), ROOT);
            token.mint(address(merkleAirDrop), 100 * 1e18);
        }
        (user1, user1PrivKey) = makeAddrAndKey("user"); // The first user on the merkle tree

    }

    function testUserCanClaim() public {
        uint256 startingBalance = token.balanceOf(user1);
        vm.startPrank(user1);
        bytes32 digest = merkleAirDrop.getMessageHash(user1, 25 * 1e18);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivKey, digest);
        merkleAirDrop.claim(user1, 25 * 1e18, PROOF_1, v, r, s);
        uint256 endingBalance = token.balanceOf(user1);
        assertEq(endingBalance - startingBalance, 25 * 1e18);
        vm.stopPrank();

        vm.expectRevert(MerkleAirDrop.MerkleAirDrop_AlreadyClaimed.selector);
        merkleAirDrop.claim(user1, 25 * 1e18, PROOF_1, v, r, s);
    }

    function testUserClaimFailsWithWrongProof() public {
        vm.startPrank(user1);
        bytes32 digest = merkleAirDrop.getMessageHash(user1, 25 * 1e18);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivKey, digest);
        bytes32[] memory wrongProof = new bytes32[](2);
        wrongProof[0] = PROOF_OF_USER1_1;
        wrongProof[1] = bytes32(0); // Invalid proof
        vm.expectRevert(MerkleAirDrop.MerkleAirDrop_InvalidMerkleProof.selector);
        merkleAirDrop.claim(user1, 25 * 1e18, wrongProof, v, r, s);
        vm.stopPrank();
    }

    function testGasPayerCanClaimForUser() public {
        uint256 startingBalance = token.balanceOf(user1);
        // Sign the message 
        bytes32 digest = merkleAirDrop.getMessageHash(user1, 25 * 1e18);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivKey, digest);
        
        vm.startPrank(gasPayer);
        merkleAirDrop.claim(user1, 25 * 1e18, PROOF_1, v, r, s);
        uint256 endingBalance = token.balanceOf(user1);
        vm.stopPrank();
        assertEq(endingBalance - startingBalance, 25 * 1e18);
    }

    function testClaimFailsWithInvalidSignature() public {
        vm.startPrank(user1);
        bytes32 digest = merkleAirDrop.getMessageHash(user1, 25 * 1e18);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivKey, digest);
        // Tampering with the signature by changing 's'
        s = bytes32(uint256(s) + 1);
        vm.expectRevert(MerkleAirDrop.MerkleAirDrop_InvalidSignature.selector);
        merkleAirDrop.claim(user1, 25 * 1e18, PROOF_1, v, r, s);
        vm.stopPrank();
    }
}