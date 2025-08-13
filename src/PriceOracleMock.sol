// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract PriceOracleMock is Ownable {
    mapping(bytes32 => uint256) public priceX18;
    event PriceSet(address base, address quote, uint256 px);

    constructor() Ownable(msg.sender) {}

    function setPrice(address base, address quote, uint256 px) external onlyOwner {
        priceX18[_key(base, quote)] = px;
        priceX18[_key(quote, base)] = (1e36) / px;
        emit PriceSet(base, quote, px);
    }

    function getPriceX18(address base, address quote) external view returns (uint256) {
        return priceX18[_key(base, quote)];
    }

    function _key(address a, address b) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(a, b));
    }
}
