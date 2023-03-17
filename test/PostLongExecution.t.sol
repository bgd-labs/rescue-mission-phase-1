// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { GovHelpers, IAaveGovernanceV2 } from "aave-helpers/GovHelpers.sol";
import { IERC20 } from "solidity-utils/contracts/oz-common/interfaces/IERC20.sol";
import { IGovernanceStrategy } from "aave-address-book/AaveGovernanceV2.sol";
import "forge-std/Test.sol";
import { IAaveMerkleDistributor } from "../src/contracts/interfaces/IAaveMerkleDistributor.sol";

contract TestPayload {
    event PayloadExecuted(bool indexed payloadExecuted);

    function execute() external {
        emit PayloadExecuted(true);
    }
}

contract PostLongExecutionTest is Test {
    // proposal id corresponding rescue mission phase 1 long executor
    uint256 public constant PROPOSAL_ID = 166;

    address public constant AAVE_HOLDER =
        0x25F2226B597E8F9514B3F68F00f494cF4f286491;
    address public constant STK_AAVE_HOLDER =
        0x80845058350B8c3Df5c3015d8a717D64B3bF9267;
    address public constant STK_AAVE =
        0x4da27a545c0c5B758a6BA100e3a049001de870f5;

    address public constant LEND = 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03;

    IAaveMerkleDistributor public constant AAVE_MERKLE_DISTRIBUTOR =
    IAaveMerkleDistributor(0xa88c6D90eAe942291325f9ae3c66f3563B93FE10);

    bytes32 constant MERKLE_ROOT =
        0x46cf998dfa113fd51bc43bf8931a5b20d45a75471dde5df7b06654e94333a463;

    // test claimer constants
    address constant claimer = 0xBfb94e2D0aC667d168A2610272Cc43909b374D3d;
    uint8 constant claimerIndex = 100;
    uint256 constant claimerAmount = 28050046686743540322700;
    bytes32[] claimerMerkleProof = [
        bytes32(
            0x88061eee37b2ecc424165edd68056ea2e15c070e841e40afff067cc14541a428
        ),
    0x4adfb35ca308c94f930caeaee5ae612e86d6dbf8d1f0dff40365e60b77981a99,
    0xe30285e3ba1a665ef849f7ef62096bee76c4cf7f6c5c9ab00c6d1461f54607d9,
    0x78e491d9d3567407b1edcf2b1f8536664a313eefef7804ab83572f821c08772d,
    0x93712ab6274c084ed47181fc1ad1aab52017e1165e291a2c7ef1c2feb83f57cf,
    0x20eb6bfb30f8150b8da4dff2fd81319a049bb65eaf8a03dc5490f99ea85b742a,
    0x970c88f3a94d75e6ae3156a39c68a38b04528f038749debd043c5a2dc8952cc4,
    0xc8a1d176886057ab4a570c834952b53ba49128e44356e5af7fbb9e20bdc0322e
    ];

    event PayloadExecuted(bool indexed payloadExecuted);
    event Claimed(
        uint256 index,
        address indexed account,
        uint256 amount,
        uint256 indexed distributionId
    );

    function setUp() public {
        // block corresponding to march 6th 2023  (do not change)
        vm.createSelectFork(vm.rpcUrl("ethereum"), 16846580);

        uint256 executionTime = GovHelpers
            .GOV
            .getProposalById(PROPOSAL_ID)
            .executionTime;
        vm.warp(executionTime + 1);

        hoax(GovHelpers.AAVE_WHALE);
        GovHelpers.GOV.execute(PROPOSAL_ID);

        // small test to see that proposal passed (as in proposal we move LEND out of AAVE)
        assertEq(IERC20(LEND).balanceOf(GovHelpers.AAVE), 0);
    }

    function testClaimRescue() public {
        IAaveMerkleDistributor.TokenClaim[]
            memory claimTokens = new IAaveMerkleDistributor.TokenClaim[](1);
        claimTokens[0] = IAaveMerkleDistributor.TokenClaim({
            index: claimerIndex,
            amount: claimerAmount,
            merkleProof: claimerMerkleProof,
            distributionId: 0
        });

        hoax(claimer);
        vm.expectEmit(true, true, false, true);
        emit Claimed(claimerIndex, claimer, claimerAmount, 0);
        AAVE_MERKLE_DISTRIBUTOR.claim(claimTokens);

        assertEq(AAVE_MERKLE_DISTRIBUTOR.isClaimed(100, 0), true);
    }

    function testClaimMultipleTokens() public {
        address UNI_TOKEN = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

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
            distributionId: 3
        });

        hoax(0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2);
        AAVE_MERKLE_DISTRIBUTOR.claim(claimTokens);

        assertEq(AAVE_MERKLE_DISTRIBUTOR.isClaimed(25, 0), true);
        assertEq(AAVE_MERKLE_DISTRIBUTOR.isClaimed(0, 3), true);
    }

    function testTransferAave() public {
        address aaveReceiver = address(123415);

        uint256 beforeBalance = IERC20(GovHelpers.AAVE).balanceOf(AAVE_HOLDER);

        hoax(AAVE_HOLDER);
        IERC20(GovHelpers.AAVE).transfer(aaveReceiver, 100 ether);

        assertEq(IERC20(GovHelpers.AAVE).balanceOf(aaveReceiver), 100 ether);
        assertEq(
            IERC20(GovHelpers.AAVE).balanceOf(AAVE_HOLDER),
            beforeBalance - 100 ether
        );

        IGovernanceStrategy strategy = IGovernanceStrategy(
            GovHelpers.GOV.getGovernanceStrategy()
        );
        uint256 power = strategy.getVotingPowerAt(aaveReceiver, block.number);
        assertEq(power, IERC20(GovHelpers.AAVE).balanceOf(aaveReceiver));
    }

    function testTransferStkAave() public {
        address aaveReceiver = address(123415);

        uint256 beforeBalance = IERC20(STK_AAVE).balanceOf(STK_AAVE_HOLDER);

        hoax(STK_AAVE_HOLDER);
        IERC20(STK_AAVE).transfer(aaveReceiver, 100 ether);

        assertEq(IERC20(STK_AAVE).balanceOf(aaveReceiver), 100 ether);
        assertEq(
            IERC20(STK_AAVE).balanceOf(STK_AAVE_HOLDER),
            beforeBalance - 100 ether
        );

        IGovernanceStrategy strategy = IGovernanceStrategy(
            GovHelpers.GOV.getGovernanceStrategy()
        );
        uint256 power = strategy.getVotingPowerAt(aaveReceiver, block.number);
        assertEq(power, IERC20(STK_AAVE).balanceOf(aaveReceiver));
    }
}
