// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import { IERC20 } from "solidity-utils/contracts/oz-common/interfaces/IERC20.sol";
import { GovHelpers, IAaveGovernanceV2 } from "aave-helpers/GovHelpers.sol";
import { ProposalPayloadShort } from "../src/contracts/ProposalPayloadShort.sol";
import { AaveMerkleDistributor } from "../src/contracts/AaveMerkleDistributor.sol";
import { IAaveMerkleDistributor } from "../src/contracts/interfaces/IAaveMerkleDistributor.sol";
import { LendToAaveMigrator } from "../src/contracts/LendToAaveMigrator.sol";

contract ProposalPayloadShortTest is Test {
    IERC20 public constant AAVE =
        IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    address internal constant AAVE_WHALE =
        address(0x25F2226B597E8F9514B3F68F00f494cF4f286491);
    ProposalPayloadShort internal proposalPayload;
    uint256 public beforeTotalLendMigrated;
    LendToAaveMigrator public migrator;

    uint256 public constant LEND_AAVE_RATIO = 100;

    IERC20 public constant LEND =
        IERC20(0x80fB784B7eD66730e8b1DBd9820aFD29931aab03);

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("ethereum"), 16491051);

        AaveMerkleDistributor aaveMerkleDistributor = new AaveMerkleDistributor();

        // give ownership of distributor to short executor
        aaveMerkleDistributor.transferOwnership(GovHelpers.SHORT_EXECUTOR);

        // Deploy new LendToAaveMigrator implementation and rescue LEND
        LendToAaveMigrator lendToAaveMigratorImpl = new LendToAaveMigrator(
            AAVE,
            LEND,
            LEND_AAVE_RATIO
        );

        proposalPayload = new ProposalPayloadShort(
            aaveMerkleDistributor,
            address(lendToAaveMigratorImpl)
        );

        migrator = LendToAaveMigrator(
            address(proposalPayload.MIGRATOR_PROXY_ADDRESS())
        );
        beforeTotalLendMigrated = migrator._totalLendMigrated();
    }

    function testProposal() public {
        address[] memory targets = new address[](1);
        targets[0] = address(proposalPayload);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        string[] memory signatures = new string[](1);
        signatures[0] = "execute()";
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";
        bool[] memory withDelegatecalls = new bool[](1);
        withDelegatecalls[0] = true;

        uint256 proposalId = GovHelpers.createProposal(
            vm,
            GovHelpers.SPropCreateParams({
                executor: GovHelpers.SHORT_EXECUTOR,
                targets: targets,
                values: values,
                signatures: signatures,
                calldatas: calldatas,
                withDelegatecalls: withDelegatecalls,
                ipfsHash: bytes32(0)
            })
        );

        GovHelpers.passVoteAndExecute(vm, proposalId);

        _validateAaveMerkleDistribution(proposalId);
        _validateTokenRescue(proposalId);
    }

    function _validateAaveMerkleDistribution(uint256 proposalId) internal {
        IAaveGovernanceV2.ProposalWithoutVotes memory proposalData = GovHelpers
            .getProposalById(proposalId);
        // Generally, there is no reason to have more than 1 payload if using the DELEGATECALL pattern
        address payload = proposalData.targets[0];

        // from payload get data;
        ProposalPayloadShort proposalPayload = ProposalPayloadShort(payload);
        AaveMerkleDistributor aaveMerkleDistributor = AaveMerkleDistributor(
            proposalPayload.AAVE_MERKLE_DISTRIBUTOR()
        );

        IAaveMerkleDistributor.DistributionWithoutClaimed memory distribution;

        distribution = aaveMerkleDistributor.getDistribution(0);
        assertEq(distribution.token, proposalPayload.AAVE_TOKEN());
        assertEq(distribution.merkleRoot, proposalPayload.AAVE_MERKLE_ROOT());

        distribution = aaveMerkleDistributor.getDistribution(1);
        assertEq(distribution.token, proposalPayload.stkAAVE_TOKEN());
        assertEq(
            distribution.merkleRoot,
            proposalPayload.stkAAVE_MERKLE_ROOT()
        );

        distribution = aaveMerkleDistributor.getDistribution(2);
        assertEq(distribution.token, proposalPayload.USDT_TOKEN());
        assertEq(distribution.merkleRoot, proposalPayload.USDT_MERKLE_ROOT());

        distribution = aaveMerkleDistributor.getDistribution(3);
        assertEq(distribution.token, proposalPayload.UNI_TOKEN());
        assertEq(distribution.merkleRoot, proposalPayload.UNI_MERKLE_ROOT());

        assertEq(aaveMerkleDistributor.owner(), GovHelpers.SHORT_EXECUTOR);
    }

    function _validateTokenRescue(uint256 proposalId) internal {
        IAaveGovernanceV2.ProposalWithoutVotes memory proposalData = GovHelpers
            .getProposalById(proposalId);
        address payload = proposalData.targets[0];
        ProposalPayloadShort proposalPayload = ProposalPayloadShort(payload);

        LendToAaveMigrator lendToAaveMigrator = LendToAaveMigrator(
            address(proposalPayload.MIGRATOR_PROXY_ADDRESS())
        );

        uint256 totalLendAmountToRescue = proposalPayload
            .LEND_TO_MIGRATOR_RESCUE_AMOUNT() +
            proposalPayload.LEND_TO_LEND_RESCUE_AMOUNT();

        assertEq(
            AAVE.balanceOf(address(proposalPayload.AAVE_MERKLE_DISTRIBUTOR())),
            totalLendAmountToRescue / LEND_AAVE_RATIO
        );
        assertEq(
            migrator._totalLendMigrated(),
            beforeTotalLendMigrated + totalLendAmountToRescue
        );
    }
}
