// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Token
 * @author Mossad ElMahgob
 * @notice This Contract Is The ERC20 Token That Will Be Used To Airdrop.
 */
contract Token is ERC20("Token", "TKN"), Ownable {
    
    constructor(address owner) Ownable(owner) {
    }


    /**
     * @notice This Function Is Used To Mint Tokens.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

}

interface IToken is IERC20 {
    function mint(address to, uint256 amount) external;
}