// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {DiamondVaultFacetV1} from "../contracts/facets/DiamondVaultFacetV1.sol";
import {IERC20} from "../contracts/interfaces/IERC20.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

contract DiamondVaultFacetV1Test is Test {
    DiamondVaultFacetV1 depositFacet;
    ERC20Mock erc20;
    uint256 initialBalance = 10000 * 10 ** 18;

    function setUp() public {
        depositFacet = new DiamondVaultFacetV1();
        erc20 = new ERC20Mock(initialBalance, address(this));
    }

    function test_DepositNative() public payable {
        vm.deal(address(this), 1 ether);
        uint256 sentValue = 1 ether;

        (bool success,) = address(depositFacet).call{value: sentValue}(abi.encodeWithSignature("depositNative()"));
        assertTrue(success, "Native deposit should succeed.");

        uint256 contractBalance = address(depositFacet).balance;
        assertEq(contractBalance, sentValue, "Contract balance should be equal to the sent value.");

        uint256 userBalance = depositFacet.balances(address(0), address(this));
        assertEq(userBalance, sentValue, "User balance should be equal to the sent value.");
    }

    function testFuzz_DepositNative(uint256 _amount) public payable {
        vm.assume(_amount > 0);
        vm.deal(address(this), _amount);

        (bool success,) = address(depositFacet).call{value: _amount}(abi.encodeWithSignature("depositNative()"));
        assertTrue(success, "Native deposit should succeed.");

        uint256 contractBalance = address(depositFacet).balance;
        assertEq(contractBalance, _amount, "Contract balance should be equal to the sent value.");

        uint256 userBalance = depositFacet.balances(address(0), address(this));
        assertEq(userBalance, _amount, "User balance should be equal to the sent value.");
    }

    function test_ZeroDepositNative() public payable {
        (bool success,) = address(depositFacet).call{value: 0}(abi.encodeWithSignature("depositNative()"));
        assertTrue(!success, "Native deposit shouldn't succeed.");
    }

    function test_DepositERC20() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        erc20.approve(address(depositFacet), depositAmount);
        depositFacet.depositERC20(address(erc20), depositAmount);

        uint256 contractBalance = erc20.balanceOf(address(depositFacet));
        assertEq(contractBalance, depositAmount, "Contract balance should be equal to the deposit amount.");

        uint256 userBalance = depositFacet.balances(address(erc20), address(this));
        assertEq(userBalance, depositAmount, "User balance should be equal to the deposit amount.");
    }

    function testFuzz_DepositERC20(uint256 depositAmount) public {
        vm.assume(depositAmount <= initialBalance && depositAmount > 0);

        erc20.approve(address(depositFacet), depositAmount);
        depositFacet.depositERC20(address(erc20), depositAmount);

        uint256 contractBalance = erc20.balanceOf(address(depositFacet));
        assertEq(contractBalance, depositAmount, "Contract balance should be equal to the deposit amount.");

        uint256 userBalance = depositFacet.balances(address(erc20), address(this));
        assertEq(userBalance, depositAmount, "User balance should be equal to the deposit amount.");
    }

    function testFail_ZeroDepositERC20() public {
        erc20.approve(address(depositFacet), 0);
        depositFacet.depositERC20(address(erc20), 0);
    }
}
