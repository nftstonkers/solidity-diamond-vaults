// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Modifier {
    error MIN_UNMET();

    modifier validAmount(uint256 amount) {
        if (amount <= 0) {
            revert MIN_UNMET();
        }
        _;
    }
}
