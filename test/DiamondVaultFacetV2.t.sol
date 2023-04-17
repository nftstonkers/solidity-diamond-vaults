// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {DiamondVaultFacetV2} from "../contracts/facets/DiamondVaultFacetV2.sol";
import {IERC20} from "../contracts/interfaces/IERC20.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

contract MockDiamondVaultFacetV2 is DiamondVaultFacetV2 {
    function setTestBalance(address _token, address _user, uint256 _amount) public {
        data.balances[_token][_user] = _amount;
    }

    function getTestBalance(address _token, address _user) public view returns (uint256) {
        return data.balances[_token][_user];
    }
}

contract DiamondVaultFacetV2Test is Test {
    MockDiamondVaultFacetV2 diamondVaultFacetV2;
    ERC20Mock erc20;
    uint256 initialBalance = 10000 * 10 ** 18;

    function setUp() public {
        diamondVaultFacetV2 = new MockDiamondVaultFacetV2();
        erc20 = new ERC20Mock(initialBalance, address(diamondVaultFacetV2));
        diamondVaultFacetV2.setTestBalance(address(0), address(this), initialBalance);
        diamondVaultFacetV2.setTestBalance(address(erc20), address(this), initialBalance);
    }

    function test_WithdrawNative() public {
        uint256 amount = 2 ether;
        uint256 initialUserNativeBalance = address(this).balance;
        uint256 initialUserVaultBalance = diamondVaultFacetV2.getTestBalance(address(0), address(this));

        vm.deal(address(diamondVaultFacetV2), amount);

        diamondVaultFacetV2.withdraw(address(0), amount);

        uint256 userNativeBalance = address(this).balance;
        assertEq(
            userNativeBalance,
            initialUserNativeBalance + amount,
            "User native balance should increase by the withdrawn amount."
        );

        uint256 userVaultNativeBalance = diamondVaultFacetV2.getTestBalance(address(0), address(this));
        assertEq(
            userVaultNativeBalance,
            initialUserVaultBalance - 2 ether,
            "User vault native balance should decrease by the withdrawn amount."
        );
    }

    function testFuzz_WithdrawNative(uint256 amount) public {
        vm.assume(amount > 0 && amount <= initialBalance);
        uint256 initialUserNativeBalance = address(this).balance;
        uint256 initialUserVaultBalance = diamondVaultFacetV2.getTestBalance(address(0), address(this));
        vm.deal(address(diamondVaultFacetV2), amount);

        diamondVaultFacetV2.withdraw(address(0), amount);

        uint256 userNativeBalance = address(this).balance;
        assertEq(
            userNativeBalance,
            initialUserNativeBalance + amount,
            "User native balance should increase by the withdrawn amount."
        );

        uint256 userVaultNativeBalance = diamondVaultFacetV2.getTestBalance(address(0), address(this));
        assertEq(
            userVaultNativeBalance,
            initialUserVaultBalance - amount,
            "User vault native balance should decrease by the withdrawn amount."
        );
    }

    function testFail_ZeroWithdrawNative() public {
        diamondVaultFacetV2.withdraw(address(0), 0);
    }

    function test_WithdrawInsufficientBalanceNative() public {
        uint256 amount = 20000 * 10 ** 18;
        vm.deal(address(diamondVaultFacetV2), amount);

        try diamondVaultFacetV2.withdraw(address(0), amount) {
            fail("Withdrawal should fail due to insufficient balance.");
        } catch Error(string memory reason) {
            assertEq(reason, "INSUFFICIENT_BAL", "Error reason should be 'INSUFFICIENT_BAL'.");
        }
    }

    function test_WithdrawERC20() public {
        uint256 amount = 1000 * 10 ** 18;

        diamondVaultFacetV2.withdraw(address(erc20), amount);

        uint256 userERC20Balance = erc20.balanceOf(address(this));
        assertEq(userERC20Balance, amount, "User ERC20 balance should increase by the withdrawn amount.");

        uint256 userVaultERC20Balance = diamondVaultFacetV2.getTestBalance(address(erc20), address(this));
        assertEq(
            userVaultERC20Balance,
            initialBalance - amount,
            "User vault ERC20 balance should decrease by the withdrawn amount."
        );
    }

    function testFuzz_WithdrawERC20(uint256 amount) public {
        vm.assume(amount <= initialBalance && amount > 0);
        diamondVaultFacetV2.withdraw(address(erc20), amount);

        uint256 userERC20Balance = erc20.balanceOf(address(this));
        assertEq(userERC20Balance, amount, "User ERC20 balance should increase by the withdrawn amount.");

        uint256 userVaultERC20Balance = diamondVaultFacetV2.getTestBalance(address(erc20), address(this));
        assertEq(
            userVaultERC20Balance,
            initialBalance - amount,
            "User vault ERC20 balance should decrease by the withdrawn amount."
        );
    }

    function testFail_ZeroDepositERC20() public {
        diamondVaultFacetV2.withdraw(address(erc20), 0);
    }

    function test_WithdrawInsufficientBalanceERC20() public {
        uint256 amount = 20000 * 10 ** 18;

        try diamondVaultFacetV2.withdraw(address(erc20), amount) {
            fail("Withdrawal should fail due to insufficient balance.");
        } catch Error(string memory reason) {
            assertEq(reason, "INSUFFICIENT_BAL", "Error reason should be 'INSUFFICIENT_BAL'.");
        }
    }

    receive() external payable {}
}
