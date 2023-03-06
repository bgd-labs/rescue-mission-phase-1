// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { GovHelpers, IAaveGovernanceV2 } from "aave-helpers/GovHelpers.sol";
import { IERC20 } from "solidity-utils/contracts/oz-common/interfaces/IERC20.sol";
import { IGovernanceStrategy } from 'aave-address-book/AaveGovernanceV2.sol';
import "forge-std/Test.sol";

contract TestPayload {
    event PayloadExecuted(bool indexed payloadExecuted);

    function execute() external {
        emit PayloadExecuted(true);
    }
}

contract PostExecutionTest is Test {
    // proposal id corresponding rescue mission phase 1 long executor
    uint256 public constant PROPOSAL_ID = 166;

    address public constant AAVE_HOLDER =
        0x25F2226B597E8F9514B3F68F00f494cF4f286491;
    address public constant STK_AAVE_HOLDER =
        0x80845058350B8c3Df5c3015d8a717D64B3bF9267;
    address public constant STK_AAVE =
        0x4da27a545c0c5B758a6BA100e3a049001de870f5;

    address public constant LEND = 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03;

    event PayloadExecuted(bool indexed payloadExecuted);

    function setUp() public {
        // block corresponding to march 6th 2023  (do not change)
        vm.createSelectFork(vm.rpcUrl("ethereum"), 16768250);

        GovHelpers.passVoteAndExecute(vm, PROPOSAL_ID);

        vm.roll(block.number + 10);

        // small test to see that proposal passed (as in proposal we move LEND out of AAVE)
        assertEq(IERC20(LEND).balanceOf(GovHelpers.AAVE), 0);

    }

    function testCreateAndPassShortProposal() public {
        uint256 proposalId = _createProposal(false);

        vm.roll(GovHelpers.GOV.getProposalById(proposalId).startBlock + 1);

        hoax(GovHelpers.AAVE_WHALE);
        GovHelpers.GOV.submitVote(proposalId, true);
        uint256 endBlock = GovHelpers.GOV.getProposalById(proposalId).endBlock;
        vm.roll(endBlock + 1);
        GovHelpers.GOV.queue(proposalId);
        uint256 executionTime = GovHelpers.GOV.getProposalById(proposalId).executionTime;
        vm.warp(executionTime + 1);

        vm.expectEmit(true, false, false, true);
        emit PayloadExecuted(true);
        GovHelpers.GOV.execute(proposalId);
    }

    function testCreateAndPassLongProposal() public {
        uint256 proposalId = _createProposal(true);

        vm.roll(GovHelpers.GOV.getProposalById(proposalId).startBlock + 1);

        hoax(GovHelpers.AAVE_WHALE);
        GovHelpers.GOV.submitVote(proposalId, true);
        uint256 endBlock = GovHelpers.GOV.getProposalById(proposalId).endBlock;
        vm.roll(endBlock + 1);
        GovHelpers.GOV.queue(proposalId);
        uint256 executionTime = GovHelpers.GOV.getProposalById(proposalId).executionTime;
        vm.warp(executionTime + 1);

        vm.expectEmit(true, false, false, true);
        emit PayloadExecuted(true);
        GovHelpers.GOV.execute(proposalId);
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

    function _createProposal(bool long) internal returns (uint256) {
        TestPayload proposalPayload = new TestPayload();

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

        return
            GovHelpers.createProposal(
                vm,
                GovHelpers.SPropCreateParams({
                    executor: long
                        ? GovHelpers.LONG_EXECUTOR
                        : GovHelpers.SHORT_EXECUTOR,
                    targets: targets,
                    values: values,
                    signatures: signatures,
                    calldatas: calldatas,
                    withDelegatecalls: withDelegatecalls,
                    ipfsHash: bytes32(0)
                })
            );
    }
}
