// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {DepositFacet} from "../contracts/facets/DepositFacet.sol";
import {IERC20} from "../contracts/interfaces/IERC20.sol";
import {}
import "../interfaces/IERC20.sol";
import "../mocks/ERC20Mock.sol";

contract DepositFacetTest is Test {
    DepositFacet depositFacet;
    ERC20Mock erc20;
    uint256 initialBalance = 10000 * 10**18;

    function setUp() public {
        depositFacet = new DepositFacet();
        erc20 = new ERC20Mock(initialBalance);
    }

    /// Test case for depositNative function
    function testDepositNative() public payable {
        uint256 sentValue = 5 ether;

        // Call the depositNative function with `sentValue` amount of ether
        (bool success, ) = address(depositFacet).call{value: sentValue}(abi.encodeWithSignature("depositNative()"));
        assertTrue(success, "Native deposit should succeed.");

        uint256 contractBalance = address(depositFacet).balance;
        assertEq(contractBalance, sentValue, "Contract balance should be equal to the sent value.");

        uint256 userBalance = depositFacet.vault().balances[address(0)][address(this)];
        assertEq(userBalance, sentValue, "User balance should be equal to the sent value.");
    }

    /// Test case for depositERC20 function
    function testDepositERC20() public {
        uint256 depositAmount = 1000 * 10**18;

        // Approve the depositFacet contract to spend `depositAmount` tokens on behalf of the test contract
        erc20.approve(address(depositFacet), depositAmount);

        // Call the depositERC20 function with `depositAmount` amount of tokens
        depositFacet.depositERC20(address(erc20), depositAmount);

        uint256 contractBalance = erc20.balanceOf(address(depositFacet));
        assertEq(contractBalance, depositAmount, "Contract balance should be equal to the deposit amount.");

        uint256 userBalance = depositFacet.vault().balances[address(erc20)][address(this)];
        assertEq(userBalance, depositAmount, "User balance should be equal to the deposit amount.");
    }
}
