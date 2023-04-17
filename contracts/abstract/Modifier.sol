// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Modifier {
    modifier validAmount(uint256 amount) {
        require(amount > 0, "MIN_DEPOSIT_UNMET");
        _;
    }
}
