// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import {AaveMerkleDistributor} from '../../src/contracts/AaveMerkleDistributor.sol';
import {InitializableAdminUpgradeabilityProxy} from '../../src/contracts/dependencies/upgradeability/InitializableAdminUpgradeabilityProxy.sol';
import {IERC20} from '../../src/contracts/dependencies/contracts/IERC20.sol';
import {IAaveMerkleDistributor} from '../../src/contracts/interfaces/IAaveMerkleDistributor.sol';

contract AaveMerkleDistributorTest is Test {
    IERC20 constant AAVE_TOKEN =
        IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    bytes32 constant MERKLE_ROOT =
        0x945bde6d8f033d404d8be79d38012422a868723ffc5cc5cfd91951c51c791714;
    address AAVE_MERKLE_DISTRIBUTOR_IMPL;

    IAaveMerkleDistributor aaveMerkleDistributor;

    function setUp() public {
        AAVE_MERKLE_DISTRIBUTOR_IMPL = address(new AaveMerkleDistributor());

        // deploy proxy
        InitializableAdminUpgradeabilityProxy distributorProxy = new InitializableAdminUpgradeabilityProxy();
        // initialize
        distributorProxy.initialize(
            AAVE_MERKLE_DISTRIBUTOR_IMPL,
            address(1),
            abi.encodeWithSignature(
                'initialize(address,bytes32)',
                address(AAVE_TOKEN),
                MERKLE_ROOT
            )
        );

        aaveMerkleDistributor = IAaveMerkleDistributor(
            address(distributorProxy)
        );

        // assertEq(aaveMerkleDistributor.token, address(AAVE_TOKEN));

        // add funds to distributor contract
        // deal(address(AAVE_TOKEN), address(distributorProxy), 10000e18);
        // assertEq(AAVE_TOKEN.balanceOf(AAVE_MERKLE_DISTRIBUTOR_IMPL), 10000e18);
    }

    function testRevision() public {
        assertEq(0, 0);
        // AaveMerkleDistributor distributor = AaveMerkleDistributor(address(1));
        // assertEq(distributor.REVISION, 0x1);
    }

    function testInitialize() public {
        // AaveMerkleDistributor distributor = AaveMerkleDistributor(address(1));
    }

    function testIsClaimed() public {}

    function testClaim() public {}
}
