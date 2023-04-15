// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IDiamondVault.sol";
import "./libraries/AppStorage.sol";

contract DiamondVaultFacetV1 is IDiamondVault {
    function deposit(uint256 amount) external override {
        AppStorage.Vault storage vault = AppStorage.vault();
        vault.balance[msg.sender] += amount;
        vault.totalBalance += amount;
    }
}