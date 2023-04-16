// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AppStorage} from "../storage/AppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {Modifier} from "../abstract/Modifier.sol";

contract DiamondVaultFacetV1 is Modifier {
    event VaultDeposit(address indexed _contract, address indexed _user, uint256 amount);

    AppStorage internal data;

    function depositNative() external payable validAmount(msg.value) {
        _credit(address(0), msg.sender, msg.value);
        emit VaultDeposit(address(0), msg.sender, msg.value);
    }

    function depositERC20(address _token, uint256 amount) external validAmount(amount) {
        IERC20(_token).transferFrom(msg.sender, address(this), amount);
        _credit(_token, msg.sender, amount);

        emit VaultDeposit(_token, msg.sender, amount);
    }

    function balances(address _token) external view returns (uint256) {
        return data.balances[_token][msg.sender];
    }

    function _credit(address _token, address _user, uint256 amount) internal {
        data.balances[_token][_user] += amount;
    }
}
