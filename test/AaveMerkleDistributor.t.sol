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
        0xbdc6d4494ce5e7be1159836917a57eff00a025b7064210f3f011567a14ef5c59;

    // test claimer constants
    address constant claimer = 0x00Af54516A94D1aC9eed55721215C8DE9970CdeE;
    uint8 constant claimerIndex = 0;
    uint256 constant claimerAmount = 34157400000000000000;
    bytes32[] claimerMerkleProof = [
        bytes32(
            0x5c9f2109f2d7c2fa9117625521ca73e3cacad26ac5ec1db1bc6cb118321a7116
        ),
        0x895d27f5710471ac73a49381afb2bda42175ee45e3917ba6cf9cd40d0c15c26a,
        0x4ad6c2226cd74e826b23480f6a3ddc0d6ac3b28901e8b7fb42891b80ac29c979,
        0x877cb4c2016c215e977781388c3b186ea68f02dda7c16f6ebcb80dc38ef9e1ad,
        0x9ae4762db2d1570c6575cde35b1d7a35e209d5ddf51b47f2a3b4cd8051e3c8d2,
        0x5563d6d2d467009e4460116ec2be772960606104845ff627dcf1f834422efcfb,
        0x5214e0f65a072e81fe6cbaafe2612bcc5bd6b24f179b312e262eebc693b7a04b,
        0x9dd565bf91f9b233c159889ea84c319c1f399ef388d8c9990484a6d8a5c8352e
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
        vm.createSelectFork(vm.rpcUrl("ethereum"), 16491051);

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
