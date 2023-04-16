// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AppStorage} from "../libraries/AppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {Modifier} from "../abstract/Modifier.sol";

contract WithdrawFacet is Modifier {
    event VaultWithdraw(address indexed _contract, address indexed _user, uint256 amount);

    error INSUFF_BAL();
    error TRAN_FAIL();

    function withdrawNative(uint256 amount) external validAmount(amount) {
        _debit(address(0), msg.sender, amount);
        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) {
            revert TRAN_FAIL();
        }
        emit VaultWithdraw(address(0), msg.sender, amount);
    }

    function withdrawERC20(address _token, uint256 amount) external validAmount(amount) {
        _debit(_token, msg.sender, amount);
        IERC20(_token).transfer(msg.sender, amount);
        emit VaultWithdraw(_token, msg.sender, amount);
    }

    function _debit(address _token, address _user, uint256 amount) internal {
        AppStorage.Vault storage vault = AppStorage.vault();

        if (vault.balances[_token][_user] < amount) {
            revert INSUFF_BAL();
        }
        vault.balances[_token][_user] -= amount;
    }
}
