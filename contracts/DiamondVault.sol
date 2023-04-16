// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Diamond} from "diamond-3-hardhat/Diamond.sol";

contract DiamondVault is Diamond {
    constructor(address _diamondCutFacet) payable Diamond(msg.sender, _diamondCutFacet) {}
}
