// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AppStorage} from "../storage/AppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {Modifier} from "../abstract/Modifier.sol";

/**
 * @dev DiamondVaultFacetVw has all functions allowing withdrawal of any native or ERC20 token.
 */
contract DiamondVaultFacetV2 is Modifier {
    /// @dev This emits whenever there is any withdraw from the Vault
    event VaultWithdraw(address indexed _contract, address indexed _user, uint256 amount);

    AppStorage internal data;

    /// @notice Withdraw the requested Native or ERC20 token from the Vault
    /// @dev Token Address for Native token is assumed to be address(0), VaultWithdraw event emitted
    /// @param _token The contract address of the token
    /// @param _amount Amount to be withdrawal
    function withdraw(address _token, uint256 _amount) external validAmount(_amount) {
        uint256 userBalance = data.balances[_token][msg.sender];
        require(userBalance >= _amount, "INSUFFICIENT_BAL");
        data.balances[_token][msg.sender] = userBalance - _amount;

        if (_token == address(0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_token).transfer(msg.sender, _amount);
        }
        emit VaultWithdraw(_token, msg.sender, _amount);
    }
}
