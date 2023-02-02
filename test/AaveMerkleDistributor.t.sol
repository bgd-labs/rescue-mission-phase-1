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
        0x46cf998dfa113fd51bc43bf8931a5b20d45a75471dde5df7b06654e94333a463;

    // test claimer constants
    address constant claimer = 0x00Af54516A94D1aC9eed55721215C8DE9970CdeE;
    uint8 constant claimerIndex = 0;
    uint256 constant claimerAmount = 34157400000000000000;
    bytes32[] claimerMerkleProof = [
        bytes32(
            0x63d0b615933f386743984cf04df28f9b3baab05af7ba535d8252bf2a9b4e9369
        ),
        0x72da0db92b21f7872ef817479518c88dabdb099197221bfa9062c37c7cc55082,
        0x3daa6f16f2ad45d04fa2882e9d6db2d7f38c3d81bb7da0fb526b31af337ced63,
        0x17ecaf65a69e4963f3b295964ff5fd3431d7dc89786ad4a48da05e9091f2223a,
        0x93712ab6274c084ed47181fc1ad1aab52017e1165e291a2c7ef1c2feb83f57cf,
        0x20eb6bfb30f8150b8da4dff2fd81319a049bb65eaf8a03dc5490f99ea85b742a,
        0x970c88f3a94d75e6ae3156a39c68a38b04528f038749debd043c5a2dc8952cc4,
        0xc8a1d176886057ab4a570c834952b53ba49128e44356e5af7fbb9e20bdc0322e
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
        vm.createSelectFork(vm.rpcUrl("ethereum"), 16542275);

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

        IAaveMerkleDistributor.TokenClaim[]
            memory claimTokens = new IAaveMerkleDistributor.TokenClaim[](1);
        claimTokens[0] = IAaveMerkleDistributor.TokenClaim({
            index: claimerIndex,
            amount: claimerAmount,
            merkleProof: claimerMerkleProof,
            distributionId: 0
        });

        hoax(claimer);
        aaveMerkleDistributor.claim(claimTokens);

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

        IAaveMerkleDistributor.TokenClaim[]
            memory claimTokens = new IAaveMerkleDistributor.TokenClaim[](1);
        claimTokens[0] = IAaveMerkleDistributor.TokenClaim({
            index: claimerIndex,
            amount: claimerAmount,
            merkleProof: claimerMerkleProof,
            distributionId: 0
        });

        hoax(claimer);
        aaveMerkleDistributor.claim(claimTokens);

        assertEq(aaveMerkleDistributor.isClaimed(0, 0), true);
    }

    function testClaimWhenCallerNotAccount() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(AAVE_TOKEN);

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = MERKLE_ROOT;

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);

        IAaveMerkleDistributor.TokenClaim[]
            memory claimTokens = new IAaveMerkleDistributor.TokenClaim[](1);
        claimTokens[0] = IAaveMerkleDistributor.TokenClaim({
            index: claimerIndex,
            amount: claimerAmount,
            merkleProof: claimerMerkleProof,
            distributionId: 0
        });

        vm.expectRevert(bytes("MerkleDistributor: Invalid proof."));
        aaveMerkleDistributor.claim(claimTokens);

        assertEq(aaveMerkleDistributor.isClaimed(0, 0), false);
    }

    function testClaimMultipleTokens() public {
        address UNI_TOKEN = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
        deal(
            address(UNI_TOKEN),
            address(aaveMerkleDistributor),
            10000000 ether
        );

        address[] memory tokens = new address[](2);
        tokens[0] = address(AAVE_TOKEN);
        tokens[1] = address(UNI_TOKEN);

        bytes32[] memory merkleRoots = new bytes32[](2);
        merkleRoots[0] = MERKLE_ROOT;
        merkleRoots[
            1
        ] = 0x0d02ecdaab34b26ed6ffa029ffa15bc377852ba0dc0e2ce18927d554ea3d939e;

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);

        bytes32[] memory uniProof = new bytes32[](2);
        uniProof[
            0
        ] = 0x4a280bc931d097902aecaab74efc351e52fc64d6671f2c367bf9cf082f536beb;
        uniProof[
            1
        ] = 0xf350ae0dbd952e26b71b8a1221b34f58ba28307f6ec6beca25e0cf3116ff154f;

        bytes32[] memory aaveProof = new bytes32[](6);
        aaveProof[
            0
        ] = 0xe3fa4410a98d607c1a3998c5909077d3704f237c54e7e1efc55770a5c34a0d3a;
        aaveProof[
            1
        ] = 0xc2ce9657a14abf91de36abb0117cff51520ba9ccfa4a36a9c54376938a577584;
        aaveProof[
            2
        ] = 0x9c7e98996455158e0ff16f5612ef668fae9374ef0be8ba3f4d020369521542e1;
        aaveProof[
            3
        ] = 0x9c572b9c47e83c7d60076a98eb5afdb7b2e95c9c01404f387a447e9d38ddc7b6;
        aaveProof[
            4
        ] = 0x88f162d63b680096ea25bdc6a9b3d1580ce1ec2c18187d9653a2a9231b35883f;
        aaveProof[
            5
        ] = 0x8dedbbeb64019e1d0e8e5a9c35c24a47f2dcd239a086fb558eac0c5e4e6dd074;

        IAaveMerkleDistributor.TokenClaim[]
            memory claimTokens = new IAaveMerkleDistributor.TokenClaim[](2);
        claimTokens[0] = IAaveMerkleDistributor.TokenClaim({
            index: 25,
            amount: 1153512700000000000,
            merkleProof: aaveProof,
            distributionId: 0
        });
        claimTokens[1] = IAaveMerkleDistributor.TokenClaim({
            index: 0,
            amount: 49000000000000000000,
            merkleProof: uniProof,
            distributionId: 1
        });

        hoax(0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2);
        aaveMerkleDistributor.claim(claimTokens);

        assertEq(aaveMerkleDistributor.isClaimed(25, 0), true);
        assertEq(aaveMerkleDistributor.isClaimed(0, 1), true);
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

        IAaveMerkleDistributor.TokenClaim[]
            memory claimTokens = new IAaveMerkleDistributor.TokenClaim[](1);
        claimTokens[0] = IAaveMerkleDistributor.TokenClaim({
            index: usdtIndex,
            amount: usdtAmount,
            merkleProof: usdtProof,
            distributionId: 0
        });
        hoax(usdtClaimer);
        aaveMerkleDistributor.claim(claimTokens);

        assertEq(aaveMerkleDistributor.isClaimed(0, 0), true);
    }

    function testWhenClaimDistributionDoesntExist() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(AAVE_TOKEN);

        bytes32[] memory merkleRoots = new bytes32[](1);
        merkleRoots[0] = MERKLE_ROOT;

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);

        vm.expectRevert(bytes("MerkleDistributor: Distribution dont exist"));

        IAaveMerkleDistributor.TokenClaim[]
            memory claimTokens = new IAaveMerkleDistributor.TokenClaim[](1);
        claimTokens[0] = IAaveMerkleDistributor.TokenClaim({
            index: claimerIndex,
            amount: claimerAmount,
            merkleProof: claimerMerkleProof,
            distributionId: 1
        });
        hoax(claimer);
        aaveMerkleDistributor.claim(claimTokens);
    }

    function testWhenClaimingWithoutInitializing() public {
        vm.expectRevert(bytes("MerkleDistributor: Distribution dont exist"));

        IAaveMerkleDistributor.TokenClaim[]
            memory claimTokens = new IAaveMerkleDistributor.TokenClaim[](1);
        claimTokens[0] = IAaveMerkleDistributor.TokenClaim({
            index: claimerIndex,
            amount: claimerAmount,
            merkleProof: claimerMerkleProof,
            distributionId: 0
        });
        hoax(claimer);
        aaveMerkleDistributor.claim(claimTokens);
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

        IAaveMerkleDistributor.TokenClaim[]
            memory claimTokens = new IAaveMerkleDistributor.TokenClaim[](1);
        claimTokens[0] = IAaveMerkleDistributor.TokenClaim({
            index: claimerIndex,
            amount: claimerAmount,
            merkleProof: claimerMerkleProof,
            distributionId: 0
        });
        hoax(claimer);
        aaveMerkleDistributor.claim(claimTokens);

        assertEq(aaveMerkleDistributor.isClaimed(0, 0), true);

        hoax(claimer);
        vm.expectRevert(bytes("MerkleDistributor: Drop already claimed."));
        aaveMerkleDistributor.claim(claimTokens);
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

        IAaveMerkleDistributor.TokenClaim[]
            memory claimTokens = new IAaveMerkleDistributor.TokenClaim[](1);
        claimTokens[0] = IAaveMerkleDistributor.TokenClaim({
            index: claimerIndex,
            amount: claimerAmount,
            merkleProof: wrongProof,
            distributionId: 0
        });
        hoax(claimer);
        aaveMerkleDistributor.claim(claimTokens);
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

        IAaveMerkleDistributor.TokenClaim[]
            memory claimTokens = new IAaveMerkleDistributor.TokenClaim[](1);
        claimTokens[0] = IAaveMerkleDistributor.TokenClaim({
            index: claimerIndex,
            amount: claimerAmount,
            merkleProof: claimerMerkleProof,
            distributionId: 0
        });
        hoax(claimer);
        aaveMerkleDistributor.claim(claimTokens);
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
