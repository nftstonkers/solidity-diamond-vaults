// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library AppStorage {
    struct Vault {
        mapping(address => uint256) balance;
        uint256 totalBalance;
    }

    function vault() internal pure returns (Vault storage v) {
        bytes32 position = keccak256("diamond.vault.account");
        assembly {
            v.slot := position
        }
    }
}