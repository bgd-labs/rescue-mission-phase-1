// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';

import {AaveMerkleDistributor} from '../../src/contracts/AaveMerkleDistributor.sol';
import {InitializableAdminUpgradeabilityProxy} from '../../src/contracts/dependencies/upgradeability/InitializableAdminUpgradeabilityProxy.sol';
import {IERC20} from '../../src/contracts/dependencies/contracts/IERC20.sol';
import {IAaveMerkleDistributor} from '../../src/contracts/interfaces/IAaveMerkleDistributor.sol';
import {AaveMerkleDistributor} from '../../src/contracts/AaveMerkleDistributor.sol';

contract AaveMerkleDistributorTest is Test {
    using stdStorage for StdStorage;

    IERC20 constant AAVE_TOKEN =
        IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    bytes32 constant MERKLE_ROOT =
        0x945bde6d8f033d404d8be79d38012422a868723ffc5cc5cfd91951c51c791714;
    address AAVE_MERKLE_DISTRIBUTOR_IMPL;

    // test claimer constants
    address constant claimer = 0x00Af54516A94D1aC9eed55721215C8DE9970CdeE;
    uint8 constant claimerIndex = 0;
    uint256 constant claimerAmount = 0x3415740000000000000000;
    bytes32[] claimerMerkleProof = [
        bytes32(0x2efc7d4a0795618ec623b77ce2cf05bfa58005bdd3d057fc329e26f7b5967eb4),
        0x7b9098b576c1a875cf4773cade3d06e9d91a70e70b4e74bd67bd0d0104fd29e2,
        0xfe07447a29780b58d4d488b9637e5ef91a251d73e1e0588dc7d7af109e7e59c1,
        0x20d27e26b3d18d0ef4a9fbbe7cc42ab5ebb448edc17ba2dd7e9237b3c1d887aa,
        0xf2924fcc143b8345c309b2e51b154ad63f5d8bb57e0a2dbbc7078dd143ff562c,
        0x0d5c8fabd731b14ff5008bb93f0e24bdf3be7070b4e0a43a1e7fb4e158bec097,
        0x13b94bcc2521e71b73e178df38a735405e8d60a34ffa0bcda5a46a565fab8e9e,
        0x11f5d8d915f079cda2eee136172f7f5c8290d65c13074a305bc8dea4c59d44bf
    ];

    AaveMerkleDistributor aaveMerkleDistributor;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);

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

        aaveMerkleDistributor = AaveMerkleDistributor(
            address(distributorProxy)
        );

        assertEq(aaveMerkleDistributor.token(), address(AAVE_TOKEN));
        assertEq(aaveMerkleDistributor.merkleRoot(), MERKLE_ROOT);

        // add funds to distributor contract
        deal(address(AAVE_TOKEN), address(distributorProxy), 10000000 ether);
        assertEq(AAVE_TOKEN.balanceOf(address(aaveMerkleDistributor)), 10000e18);
    }

    function testRevision() public {
        assertEq(aaveMerkleDistributor.REVISION(), 0x1);
    }

    // TODO: this test makes it so we need to use contract instead of interface
    // to have access to claimedBitMap. It also makes it so it needs to be public
    // instead of private. Take a look at how we could improve on this  
    function testIsClaimedTrue() public {
        // prepared the claim index to overwrite
        uint256 claimedWordIndex = 0 / 256;
        uint256 claimedBitIndex = 0 % 256;

        // set up storage so address x already claimed
        stdstore
            .target(address(aaveMerkleDistributor))
            .sig(aaveMerkleDistributor.claimedBitMap.selector)
            .with_key(claimedWordIndex)
            .checked_write(1 << claimedBitIndex);
        
        assertEq(aaveMerkleDistributor.isClaimed(0), true);
    }

    function testIsClaimedFalse() public {        
        assertEq(aaveMerkleDistributor.isClaimed(0), false);
    }

    function testClaim() public {
        // Check that topic 1, topic 2, and data are the same as the following emitted event.
        vm.expectEmit(false, true, false, true);
        // The event we expect
        emit Claimed(claimerIndex, claimer, claimerAmount);

        console.log('amount::: ', claimerAmount);

        // The event we get
        aaveMerkleDistributor.claim(claimerIndex, claimer, claimerAmount, claimerMerkleProof);
    }
}
