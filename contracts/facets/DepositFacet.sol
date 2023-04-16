// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AppStorage} from "../libraries/AppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {Modifier} from "../abstract/Modifier.sol";

contract DepositFacet is Modifier {
    event VaultDeposit(address indexed _contract, address indexed _user, uint256 amount);

    function depositNative() external payable validAmount(msg.value) {
        _credit(address(0), msg.sender, msg.value);
        emit VaultDeposit(address(0), msg.sender, msg.value);
    }

    function depositERC20(address _token, uint256 amount) external validAmount(amount) {
        IERC20(_token).transferFrom(msg.sender, address(this), amount);
        _credit(_token, msg.sender, amount);

        emit VaultDeposit(_token, msg.sender, amount);
    }

    function _credit(address _token, address _user, uint256 amount) internal {
        AppStorage.Vault storage vault = AppStorage.vault();
        vault.balances[_token][_user] += amount;
    }
}
