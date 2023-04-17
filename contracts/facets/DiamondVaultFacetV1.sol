// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AppStorage} from "../storage/AppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {Modifier} from "../abstract/Modifier.sol";

/**
 * @dev DiamondVaultFacetV1 has all functions allowing depositing of any native or ERC20 token.
 */
contract DiamondVaultFacetV1 is Modifier {
    /// @dev This emits whenever there is any deposit to the Vault
    event VaultDeposit(address indexed _contract, address indexed _user, uint256 amount);

    AppStorage internal data;

    /// @notice Deposits Native token (like ETH on Ethereum or MATIC on Polygon) to the vault
    function depositNative() external payable validAmount(msg.value) {
        _credit(address(0), msg.sender, msg.value);
    }

    /// @notice Deposits any ERC20 token to the vault
    /// @dev Equivalent quanitity of ERC20 contract must be approved to the diamond contract
    /// @param _token The contract address of ERC20 token
    /// @param _amount Amount of ERC20 token to be transferred
    function depositERC20(address _token, uint256 _amount) external validAmount(_amount) {
        IERC20 token = IERC20(_token);
        require(token.allowance(msg.sender, address(this)) >= _amount, "TOKEN_NOT_APPROVED");
        token.transferFrom(msg.sender, address(this), _amount);
        _credit(_token, msg.sender, _amount);
    }

    /// @notice Queries user balance for a particular token (Native or ERC20)
    /// @dev Token Address for Native token is assumed to be address(0)
    /// @param _token The contract address of the token
    /// @param _owner User whose balance is queried
    /// @return Token balance of the queries user
    function balances(address _token, address _owner) external view returns (uint256) {
        return data.balances[_token][_owner];
    }

    /// @notice Credits user balance for the provided token contract
    /// @dev Token Address for Native token is assumed to be address(0), VaultDeposit event emitted.
    /// @param _token The contract address of the token.
    /// @param _user User whose balance is queried
    /// @param _amount Amount of token to be credited
    function _credit(address _token, address _user, uint256 _amount) internal {
        data.balances[_token][_user] += _amount;
        emit VaultDeposit(_token, _user, _amount);
    }
}
