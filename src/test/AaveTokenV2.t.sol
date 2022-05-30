// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IERC20} from "../contracts/dependencies/openZeppelin/IERC20.sol";
import {IInitializableAdminUpgradeabilityProxy} from "../contracts/interfaces/IInitializableAdminUpgradeabilityProxy.sol";
import {AaveMerkleDistributor} from "../contracts/AaveMerkleDistributor.sol";
import {AaveTokenV2} from "../contracts/AaveTokenV2.sol";

contract AaveTokenV2Test is Test {
    address public constant MIGRATOR_PROXY_ADMIN = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;
    address public constant AAVE_TOKEN_ADDRESS = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    IERC20 public constant AAVE = IERC20(AAVE_TOKEN_ADDRESS);
    IInitializableAdminUpgradeabilityProxy public constant aaveProxy = IInitializableAdminUpgradeabilityProxy(AAVE_TOKEN_ADDRESS);
    AaveMerkleDistributor aaveMerkleDistributor;
    AaveTokenV2 aaveTokenImpl;

    function setUp() public {
        aaveMerkleDistributor = new AaveMerkleDistributor();
        aaveTokenImpl = new AaveTokenV2();
    }

    function testInitialize() public {

    }
}