// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    constructor(string memory n, string memory s) ERC20(n, s) Ownable(msg.sender) {}


    function mint(address to, uint256 amt) external onlyOwner {
        _mint(to, amt);
    }
}
