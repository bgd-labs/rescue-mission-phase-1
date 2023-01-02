// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { IERC20 } from "solidity-utils/contracts/oz-common/interfaces/IERC20.sol";
import { IAaveMerkleDistributor } from "../src/contracts/interfaces/IAaveMerkleDistributor.sol";
import { AaveMerkleDistributor } from "../src/contracts/AaveMerkleDistributor.sol";

contract AaveMerkleDistributorTest is Test {
    using stdStorage for StdStorage;

    IERC20 constant AAVE_TOKEN =
        IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    IERC20 constant USDT_TOKEN =
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    bytes32 constant MERKLE_ROOT =
        0x0ef2bf07cb8d6ddde75d4d2f2c29f4c1607844a8d9ac3323205093765e6c27e3;

    // test claimer constants
    address constant claimer = 0x00Af54516A94D1aC9eed55721215C8DE9970CdeE;
    uint8 constant claimerIndex = 0;
    uint256 constant claimerAmount = 34157400000000000000;
    bytes32[] claimerMerkleProof = [
        bytes32(
            0x60629b3865ea6bfe90bed01fac620f9551df3b9f5b6071cdfafb7dc5f25b16c8
        ),
        0x694eb9355e44cde6d40789671493c9a1ccc83b41143accc2ecd185d369f5cfa2,
        0x6c8efa842d467bd3cb5418776f71ee97e5b521f88c08637478f8d7b6b2e976d4,
        0x89c692eed93b21d26dd98fd91dfe594343e9e7aac3f6da36c8d3f1ef42a4f2db,
        0xc26fe29daa07c6f803d81db43eea4106f3e096aed8e42b4d270c8b1ef7b07f06,
        0xfcc4a177604d4c133181d6a9ab07f01ad4fcf21f33e871101f765ad538f45278,
        0x707a8f4a22b043d27d54fcce3360e8e44e652806a1ec1f750b5444c0b292ce5e,
        0xa3a37899fff5decab3cf55749cfda24c1c3f7dac9b7c526079cfe160fde5c4e5
    ];

    IAaveMerkleDistributor aaveMerkleDistributor;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(
        uint256 index,
        address indexed account,
        uint256 amount,
        uint256 indexed distributionId
    );
    // this event is triggered when adding a new distribution
    event DistributionAdded(
        address indexed token,
        bytes32 indexed merkleRoot,
        uint256 indexed distributionId
    );

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("ethereum"), 15939210);

        aaveMerkleDistributor = new AaveMerkleDistributor();

        // add funds to distributor contract
        deal(
            address(AAVE_TOKEN),
            address(aaveMerkleDistributor),
            10000000 ether
        );
        assertEq(
            AAVE_TOKEN.balanceOf(address(aaveMerkleDistributor)),
            10000000e18
        );
    }

    function testAddSingleDistribution() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(AAVE_TOKEN);

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = MERKLE_ROOT;

        vm.expectEmit(true, true, true, true);
        emit DistributionAdded(tokens[0], merkleRoots[0], 0);

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);

        assertEq(aaveMerkleDistributor._nextDistributionId(), 1);

        IAaveMerkleDistributor.DistributionWithoutClaimed
            memory distribution = aaveMerkleDistributor.getDistribution(0);
        assertEq(distribution.token, address(AAVE_TOKEN));
        assertEq(distribution.merkleRoot, MERKLE_ROOT);
    }

    function testAddMultipleDistributions() public {
        address[] memory tokens = new address[](2);
        tokens[0] = address(AAVE_TOKEN);
        tokens[1] = address(1);

        bytes32[] memory merkleRoots = new bytes32[](2);
        merkleRoots[0] = MERKLE_ROOT;
        merkleRoots[1] = MERKLE_ROOT;

        vm.expectEmit(true, true, true, true);
        emit DistributionAdded(tokens[0], merkleRoots[0], 0);

        vm.expectEmit(true, true, true, true);
        emit DistributionAdded(tokens[1], merkleRoots[1], 1);

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);

        assertEq(aaveMerkleDistributor._nextDistributionId(), 2);

        IAaveMerkleDistributor.DistributionWithoutClaimed
            memory distribution = aaveMerkleDistributor.getDistribution(0);
        assertEq(distribution.token, address(AAVE_TOKEN));
        assertEq(distribution.merkleRoot, MERKLE_ROOT);

        IAaveMerkleDistributor.DistributionWithoutClaimed
            memory distribution1 = aaveMerkleDistributor.getDistribution(1);
        assertEq(distribution1.token, address(1));
        assertEq(distribution1.merkleRoot, MERKLE_ROOT);
    }

    function testAddIncompleteDistributions() public {
        address[] memory tokens = new address[](2);
        tokens[0] = address(AAVE_TOKEN);
        tokens[1] = address(AAVE_TOKEN);

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = MERKLE_ROOT;

        vm.expectRevert(
            bytes(
                "MerkleDistributor: tokens not the same length as merkleRoots"
            )
        );

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);
    }

    function testAddDistributionsWhenNotOnwer() public {
        vm.prank(address(1));

        address[] memory tokens = new address[](1);
        tokens[0] = address(AAVE_TOKEN);

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = MERKLE_ROOT;

        vm.expectRevert(bytes("Ownable: caller is not the owner"));

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);
    }

    function testIsClaimedTrue() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(AAVE_TOKEN);

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = MERKLE_ROOT;

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);

        aaveMerkleDistributor.claim(
            claimerIndex,
            claimer,
            claimerAmount,
            claimerMerkleProof,
            0
        );

        assertEq(aaveMerkleDistributor.isClaimed(0, 0), true);
    }

    function testIsClaimedFalse() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(AAVE_TOKEN);

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = MERKLE_ROOT;

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);

        vm.expectRevert(bytes("MerkleDistributor: Distribution dont exist"));

        assertEq(aaveMerkleDistributor.isClaimed(0, 1), false);
    }

    function testIsClaimedWhenWrongDistributionId() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(AAVE_TOKEN);

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = MERKLE_ROOT;

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);

        assertEq(aaveMerkleDistributor.isClaimed(0, 0), false);
    }

    function testClaim() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(AAVE_TOKEN);

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = MERKLE_ROOT;

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);

        // Check that topic 1, topic 2, and data are the same as the following emitted event.
        vm.expectEmit(true, true, false, true);
        emit Claimed(claimerIndex, claimer, claimerAmount, 0);

        // The event we get
        aaveMerkleDistributor.claim(
            claimerIndex,
            claimer,
            claimerAmount,
            claimerMerkleProof,
            0
        );

        assertEq(aaveMerkleDistributor.isClaimed(0, 0), true);
    }

    function testClaimWhenRootIsASingleNodeTree() public {
        deal(
            address(USDT_TOKEN),
            address(aaveMerkleDistributor),
            10000000 ether
        );

        address[] memory tokens = new address[](1);
        tokens[0] = address(USDT_TOKEN);

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[
            0
        ] = 0xc7ee13da36bc0398f570e2c50daea6d04645f112371489486655d566c141c156;

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);

        address usdtClaimer = 0x0eA6c16f26f6FBA884A11e3F1E1348F6bb77eEb8;
        uint256 usdtIndex = 0;
        uint256 usdtAmount = 15631946764;
        bytes32[] memory usdtProof = new bytes32[](0);
        // Check that topic 1, topic 2, and data are the same as the following emitted event.
        vm.expectEmit(true, true, false, true);
        emit Claimed(usdtIndex, usdtClaimer, usdtAmount, 0);

        // The event we get
        aaveMerkleDistributor.claim(
            usdtIndex,
            usdtClaimer,
            usdtAmount,
            usdtProof,
            0
        );

        assertEq(aaveMerkleDistributor.isClaimed(0, 0), true);
    }

    function testWhenClaimDistributionDoesntExist() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(AAVE_TOKEN);

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = MERKLE_ROOT;

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);

        vm.expectRevert(bytes("MerkleDistributor: Distribution dont exist"));
        aaveMerkleDistributor.claim(
            claimerIndex,
            claimer,
            claimerAmount,
            claimerMerkleProof,
            1
        );
    }

    function testWhenClaimingWithoutInitializing() public {
        vm.expectRevert(bytes("MerkleDistributor: Distribution dont exist"));

        aaveMerkleDistributor.claim(
            claimerIndex,
            claimer,
            claimerAmount,
            claimerMerkleProof,
            0
        );
    }

    function testWhenAlreadyClaimed() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(AAVE_TOKEN);

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = MERKLE_ROOT;

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);

        // Check that topic 1, topic 2, and data are the same as the following emitted event.
        vm.expectEmit(true, true, false, true);
        emit Claimed(claimerIndex, claimer, claimerAmount, 0);

        // The event we get
        aaveMerkleDistributor.claim(
            claimerIndex,
            claimer,
            claimerAmount,
            claimerMerkleProof,
            0
        );

        assertEq(aaveMerkleDistributor.isClaimed(0, 0), true);

        // vm.expectRevert(aaveMerkleDistributor.DropAlreadyClaimed.selector);
        vm.expectRevert(bytes("MerkleDistributor: Drop already claimed."));

        aaveMerkleDistributor.claim(
            claimerIndex,
            claimer,
            claimerAmount,
            claimerMerkleProof,
            0
        );
    }

    function testWhenInvalidProof() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(AAVE_TOKEN);

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = MERKLE_ROOT;

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);

        vm.expectRevert(bytes("MerkleDistributor: Invalid proof."));

        bytes32[] memory wrongProof = new bytes32[](1);
        wrongProof[
            0
        ] = 0x5cab84e781cb21e9e612670a3209ee46b46eeedd05c8f3827a02706640c00d0e;

        aaveMerkleDistributor.claim(
            claimerIndex,
            claimer,
            claimerAmount,
            wrongProof,
            0
        );
    }

    function testWhenNotEnoughFunds() public {
        // lower the funds of the distributor
        stdstore
            .target(address(AAVE_TOKEN))
            .sig(AAVE_TOKEN.balanceOf.selector)
            .with_key(address(aaveMerkleDistributor))
            .checked_write(1);

        address[] memory tokens = new address[](1);
        tokens[0] = address(AAVE_TOKEN);

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = MERKLE_ROOT;

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);

        vm.expectRevert(bytes("SafeMath: subtraction overflow"));

        aaveMerkleDistributor.claim(
            claimerIndex,
            claimer,
            claimerAmount,
            claimerMerkleProof,
            0
        );
    }

    function testEmergencyTokenTransfer() public {
        uint256 prevBalance = AAVE_TOKEN.balanceOf(
            address(aaveMerkleDistributor)
        );
        aaveMerkleDistributor.emergencyTokenTransfer(
            address(AAVE_TOKEN),
            address(3),
            50 ether
        );

        assertEq(AAVE_TOKEN.balanceOf(address(3)), 50 ether);
        assertEq(
            AAVE_TOKEN.balanceOf(address(aaveMerkleDistributor)),
            prevBalance - 50 ether
        );
    }

    function testEmegencyTokenTransferWhenNotOwner() public {
        vm.prank(address(1));

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        aaveMerkleDistributor.emergencyTokenTransfer(
            address(AAVE_TOKEN),
            address(3),
            50 ether
        );
    }

    function testEmergencyEthTransfer() public {
        uint256 ethAmount = 50 ether;
        uint256 prevBalance = address(3).balance;
        deal(address(aaveMerkleDistributor), ethAmount);

        aaveMerkleDistributor.emergencyEtherTransfer(address(3), ethAmount);

        assertEq(address(3).balance, prevBalance + ethAmount);
        assertEq(address(aaveMerkleDistributor).balance, 0 ether);
    }

    function testEmergencyEthTransferWhenNotOwner() public {
        deal(address(aaveMerkleDistributor), 50 ether);
        vm.prank(address(1));

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        aaveMerkleDistributor.emergencyEtherTransfer(address(3), 50 ether);
    }
}
