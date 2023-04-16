// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AppStorage} from "../storage/AppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {Modifier} from "../abstract/Modifier.sol";

contract DiamondVaultFacetV2 is Modifier {
    event VaultWithdraw(address indexed _contract, address indexed _user, uint256 amount);

    error INSUFF_BAL();
    error TRAN_FAIL();

    AppStorage internal data;

    function withdrawNative(uint256 amount) external payable validAmount(amount) {
        _debit(address(0), msg.sender, amount);
        if (!payable(msg.sender).send(amount)) {
            revert TRAN_FAIL();
        }
        // payable(msg.sender).transfer(amount);
        // emit VaultWithdraw(address(0), msg.sender, amount);
    }

    function withdrawERC20(address _token, uint256 amount) external validAmount(amount) {
        _debit(_token, msg.sender, amount);
        IERC20(_token).transfer(msg.sender, amount);
        emit VaultWithdraw(_token, msg.sender, amount);
    }

    function _debit(address _token, address _user, uint256 amount) internal {
        if (data.balances[_token][_user] < amount) {
            revert INSUFF_BAL();
        }
        data.balances[_token][_user] -= amount;
    }
}
