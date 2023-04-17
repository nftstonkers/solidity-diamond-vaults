// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(uint256 initialSupply, address holder) ERC20("ERC20Mock", "EMOCK") {
        _mint(holder, initialSupply);
    }
}
