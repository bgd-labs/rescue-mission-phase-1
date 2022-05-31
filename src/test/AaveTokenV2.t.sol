// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IERC20} from "../contracts/dependencies/openZeppelin/IERC20.sol";
import {IInitializableAdminUpgradeabilityProxy} from "../contracts/interfaces/IInitializableAdminUpgradeabilityProxy.sol";
import {AaveMerkleDistributor} from "../contracts/AaveMerkleDistributor.sol";
import {AaveTokenV2} from "../contracts/AaveTokenV2.sol";

contract AaveTokenV2Test is Test {
    address public constant MIGRATOR_PROXY_ADMIN = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

    address public constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    uint256 public constant AAVE_RESCUE_AMOUNT = 28317484543674044370842;
    address public constant USDT_TOKEN = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint256 public constant USDT_RESCUE_AMOUNT = 15631946764;
    address public constant UNI_TOKEN = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    uint256 public constant UNI_RESCUE_AMOUNT = 110947986090000000000;
    
    IERC20 public constant AAVE = IERC20(AAVE_TOKEN);
    IInitializableAdminUpgradeabilityProxy public constant aaveProxy = 
        IInitializableAdminUpgradeabilityProxy(AAVE_TOKEN);
    AaveMerkleDistributor aaveMerkleDistributor;
    AaveTokenV2 aaveTokenImpl;

    event TokensRescued(address indexed tokenRescued, address indexed aaveMerkleDistributor, uint256 amountRescued);

    function setUp() public {
        aaveMerkleDistributor = new AaveMerkleDistributor();
        aaveTokenImpl = new AaveTokenV2();
    }

    function testInitialize() public {
        address[] memory tokens = new address[](3);
        tokens[0] = AAVE_TOKEN;
        tokens[1] = USDT_TOKEN;
        tokens[2] = UNI_TOKEN;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = AAVE_RESCUE_AMOUNT;
        amounts[1] = USDT_RESCUE_AMOUNT;
        amounts[2] = UNI_RESCUE_AMOUNT;

        // vm.expectEmit(true, true, false, true);
        // emit TokensRescued(tokens[0], address(aaveMerkleDistributor), amounts[0]);
        // vm.expectEmit(true, true, false, true);
        // emit TokensRescued(tokens[1], address(aaveMerkleDistributor), amounts[1]);
        // vm.expectEmit(true, true, false, true);
        // emit TokensRescued(tokens[2], address(aaveMerkleDistributor), amounts[2]);

        vm.prank(0x61910EcD7e8e942136CE7Fe7943f956cea1CC2f7);
        aaveProxy.upgradeToAndCall(
            address(aaveTokenImpl), 
            abi.encodeWithSignature(
                "initialize(address[],uint256[],address)",
                tokens,
                amounts,
                address(aaveMerkleDistributor)
            )
        );

        assertEq(AAVE.balanceOf(address(aaveMerkleDistributor)), AAVE_RESCUE_AMOUNT);
        assertEq(IERC20(USDT_TOKEN).balanceOf(address(aaveMerkleDistributor)), USDT_RESCUE_AMOUNT);
        assertEq(IERC20(UNI_TOKEN).balanceOf(address(aaveMerkleDistributor)), UNI_RESCUE_AMOUNT);
    }
}