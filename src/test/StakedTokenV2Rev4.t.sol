// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "forge-std/Test.sol";
import {IERC20} from "../contracts/dependencies/openZeppelin/IERC20.sol";
import {IInitializableAdminUpgradeabilityProxy} from "../contracts/interfaces/IInitializableAdminUpgradeabilityProxy.sol";
import {StakedTokenV2Rev4} from "../contracts/StakedTokenV2Rev4.sol";


contract StakedTokenV2Rev4Test is Test {
    address public constant AAVE_LONG_EXECUTOR = 0x61910EcD7e8e942136CE7Fe7943f956cea1CC2f7;

    function setUp() public {}

    function testInitialize() public {}
}