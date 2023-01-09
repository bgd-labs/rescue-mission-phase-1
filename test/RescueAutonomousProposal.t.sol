// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { GovHelpers, IAaveGovernanceV2, AaveGovernanceV2 } from "aave-helpers/GovHelpers.sol";
import { RescueAutonomousProposal } from "../src/contracts/RescueAutonomousProposal.sol";
import { ProposalPayloadShort } from "../src/contracts/ProposalPayloadShort.sol";
import { AaveMerkleDistributor } from "../src/contracts/AaveMerkleDistributor.sol";
import { LendToAaveMigrator } from "../src/contracts/LendToAaveMigrator.sol";
import { IERC20 } from "solidity-utils/contracts/oz-common/interfaces/IERC20.sol";
import { IGovernancePowerDelegationToken } from "./utils/IGovernancePowerDelegationToken.sol";

string constant aaveTokenV2Artifact = "out/AaveTokenV2.sol/AaveTokenV2.json";
string constant stakedTokenV2Rev4Artifact = "out/StakedTokenV2Rev4.sol/StakedTokenV2Rev4.json";
string constant proposalPayloadLongArtifact = "out/ProposalPayloadLong.sol/ProposalPayloadLong.json";

contract RescueAutonomousProposalTest is Test {
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address public constant LEND = 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03;
    uint256 public constant LEND_AAVE_RATIO = 100;

    uint256 public constant PROPOSAL_GRACE_PERIOD = 5 days;

    bytes32 public constant LONG_IPFS_HASH = keccak256("long ifps hash");
    bytes32 public constant SHORT_IPFS_HASH = keccak256("short ifps hash");

    // executor lvl2 parameters
    address public constant ADMIN = 0xEC568fffba86c094cf06b22134B23074DFE2252c; // Aave Governance

    uint256 public beforeProposalCount;

    ProposalPayloadShort public shortPayload;
    AaveMerkleDistributor aaveMerkleDistributor;
    RescueAutonomousProposal public autonomousProposal;
    LendToAaveMigrator lendToAaveMigratorImpl;
    address public longPayload;
    address public aaveTokenV2Impl;
    address public stakedTokenV2Rev4Impl;

    event ProposalsCreated(
        address executor,
        uint256 longExecutorProposalId,
        uint256 shortExecutorProposalId,
        address longExecutorPayload,
        bytes32 longIpfsHash,
        address shortExecutorPayload,
        bytes32 shortIpfsHash
    );

    // staked token deploy params
    IERC20 public constant stakedToken = IERC20(AAVE);
    IERC20 public constant rewardToken = IERC20(AAVE);
    uint256 public constant cooldownSeconds = 864000;
    uint256 public constant unstakeWindow = 172800;
    address public constant rewardsVault =
        0x25F2226B597E8F9514B3F68F00f494cF4f286491;
    address public constant emissionManager =
        0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;
    uint128 public constant distributionDuration = 3155692600;
    string public constant name = "Staked Aave";
    string public constant symbol = "stkAAVE";
    uint8 public constant decimals = 18;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("ethereum"), 15939210);
        beforeProposalCount = GovHelpers.GOV.getProposalsCount();

        // deploy aave merkle distributor
        aaveMerkleDistributor = new AaveMerkleDistributor();
        aaveMerkleDistributor.transferOwnership(
            AaveGovernanceV2.SHORT_EXECUTOR
        );

        // deploy new implementations
        // We need to use deployCode as solidity version of aaveToken is 0.7.5 and conflicts with other contract versions (0.8.0)
        aaveTokenV2Impl = deployCode(aaveTokenV2Artifact);

        stakedTokenV2Rev4Impl = deployCode(
            stakedTokenV2Rev4Artifact,
            abi.encode(
                stakedToken,
                rewardToken,
                cooldownSeconds,
                unstakeWindow,
                rewardsVault,
                emissionManager,
                distributionDuration,
                name,
                symbol,
                decimals
            )
        );

        lendToAaveMigratorImpl = new LendToAaveMigrator(
            IERC20(AAVE),
            IERC20(LEND),
            LEND_AAVE_RATIO
        );

        // deploy proposal payloads
        shortPayload = new ProposalPayloadShort(
            aaveMerkleDistributor,
            address(lendToAaveMigratorImpl)
        );

        longPayload = deployCode(
            proposalPayloadLongArtifact,
            abi.encode(
                address(aaveMerkleDistributor),
                aaveTokenV2Impl,
                stakedTokenV2Rev4Impl
            )
        );

        // ------------- AUTONOMOUS PROPOSAL ------------- //
        autonomousProposal = new RescueAutonomousProposal(
            address(shortPayload),
            address(longPayload),
            SHORT_IPFS_HASH,
            LONG_IPFS_HASH,
            block.timestamp + 10
        );

        skip(11);
    }

    function testCreateProposalsWhenAllInfoCorrect() public {
        hoax(GovHelpers.AAVE_WHALE);
        IGovernancePowerDelegationToken(GovHelpers.AAVE).delegateByType(
            address(autonomousProposal),
            IGovernancePowerDelegationToken.DelegationType.PROPOSITION_POWER
        );

        vm.roll(block.number + 10);

        vm.expectEmit(false, false, false, true);
        emit ProposalsCreated(
            address(this),
            beforeProposalCount,
            beforeProposalCount + 1,
            address(longPayload),
            LONG_IPFS_HASH,
            address(shortPayload),
            SHORT_IPFS_HASH
        );
        autonomousProposal.create();

        // test that first proposal is lvl2 and second is ecosystem
        uint256 proposalsCount = GovHelpers.GOV.getProposalsCount();
        assertEq(proposalsCount, beforeProposalCount + 2);

        IAaveGovernanceV2.ProposalWithoutVotes memory longProposal = GovHelpers
            .getProposalById(proposalsCount - 2);
        assertEq(longProposal.targets[0], address(longPayload));
        assertEq(longProposal.ipfsHash, LONG_IPFS_HASH);
        assertEq(
            address(longProposal.executor),
            AaveGovernanceV2.LONG_EXECUTOR
        );
        assertEq(
            keccak256(abi.encode(longProposal.signatures[0])),
            keccak256(abi.encode("execute()"))
        );
        assertEq(keccak256(longProposal.calldatas[0]), keccak256(""));

        IAaveGovernanceV2.ProposalWithoutVotes memory shortProposal = GovHelpers
            .getProposalById(proposalsCount - 1);
        assertEq(shortProposal.targets[0], address(shortPayload));
        assertEq(shortProposal.ipfsHash, SHORT_IPFS_HASH);
        assertEq(
            address(shortProposal.executor),
            AaveGovernanceV2.SHORT_EXECUTOR
        );
        assertEq(
            keccak256(abi.encode(shortProposal.signatures[0])),
            keccak256(abi.encode("execute()"))
        );
        assertEq(keccak256(shortProposal.calldatas[0]), keccak256(""));
    }

    function testCreateProposalsTwice() public {
        hoax(GovHelpers.AAVE_WHALE);
        IGovernancePowerDelegationToken(GovHelpers.AAVE).delegateByType(
            address(autonomousProposal),
            IGovernancePowerDelegationToken.DelegationType.PROPOSITION_POWER
        );

        vm.roll(block.number + 10);

        autonomousProposal.create();

        vm.expectRevert(bytes("PROPOSALS_ALREADY_CREATED"));
        autonomousProposal.create();
    }

    function testCreateProposalsWithWrongLongIpfs() public {
        vm.expectRevert(bytes("LONG_PAYLOAD_IPFS_HASH_BYTES32_0"));
        new RescueAutonomousProposal(
            address(shortPayload),
            address(longPayload),
            SHORT_IPFS_HASH,
            bytes32(0),
            block.timestamp + 10
        );
    }

    function testCreateProposalsWithWrongLongPayload() public {
        vm.expectRevert(bytes("LONG_PAYLOAD_ADDRESS_0"));
        new RescueAutonomousProposal(
            address(shortPayload),
            address(0),
            SHORT_IPFS_HASH,
            LONG_IPFS_HASH,
            block.timestamp + 10
        );
    }

    function testCreateProposalsWithWrongShortIpfs() public {
        vm.expectRevert(bytes("SHORT_PAYLOAD_IPFS_HASH_BYTES32_0"));
        new RescueAutonomousProposal(
            address(shortPayload),
            address(longPayload),
            bytes32(0),
            LONG_IPFS_HASH,
            block.timestamp + 10
        );
    }

    function testCreateProposalsWithWrongShortPayload() public {
        vm.expectRevert(bytes("SHORT_PAYLOAD_ADDRESS_0"));
        new RescueAutonomousProposal(
            address(0),
            address(longPayload),
            SHORT_IPFS_HASH,
            LONG_IPFS_HASH,
            block.timestamp + 10
        );
    }




    function testVoteOnProposals() public {
        _delegateVotingPower();
        _createProposals();

        uint256 proposalsCount = GovHelpers.GOV.getProposalsCount();

        vm.roll(block.number + AaveGovernanceV2.GOV.getVotingDelay() + 1);

        autonomousProposal.vote();

        uint256 currentPower = IGovernancePowerDelegationToken(GovHelpers.AAVE)
            .getPowerCurrent(
                address(autonomousProposal),
                IGovernancePowerDelegationToken.DelegationType.VOTING_POWER
            );
        IAaveGovernanceV2.ProposalWithoutVotes memory shortProposal = GovHelpers
            .getProposalById(proposalsCount - 1);
        assertEq(shortProposal.forVotes, currentPower);

        IAaveGovernanceV2.ProposalWithoutVotes memory longProposal = GovHelpers
            .getProposalById(proposalsCount - 2);
        assertEq(longProposal.forVotes, currentPower);
    }

    function testVotingWhenProposalsNotCreated() public {
        vm.expectRevert((bytes("PROPOSALS_NOT_CREATED")));
        autonomousProposal.vote();
    }

    function _createProposals() internal {
        hoax(GovHelpers.AAVE_WHALE);
        IGovernancePowerDelegationToken(GovHelpers.AAVE).delegateByType(
            address(autonomousProposal),
            IGovernancePowerDelegationToken.DelegationType.PROPOSITION_POWER
        );
        vm.roll(block.number + 1);
        autonomousProposal.create();
    }

    function _delegateVotingPower() internal {
        hoax(GovHelpers.AAVE_WHALE);
        IGovernancePowerDelegationToken(GovHelpers.AAVE).delegateByType(
            address(autonomousProposal),
            IGovernancePowerDelegationToken.DelegationType.VOTING_POWER
        );
        vm.roll(block.number + 1);
    }
}
