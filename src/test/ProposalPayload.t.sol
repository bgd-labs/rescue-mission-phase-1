// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IERC20} from "../contracts/dependencies/openZeppelin/IERC20.sol";
import {AaveGovHelpers, IAaveGov} from "./utils/AaveGovHelpers.sol";
import {ProposalPayload} from "../contracts/ProposalPayload.sol";


contract ProposalPayloadTest is Test {
    IERC20 public constant AAVE = IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    address internal constant AAVE_WHALE = address(0x25F2226B597E8F9514B3F68F00f494cF4f286491);
    address internal proposalPayload;

    function setUp() public {
        proposalPayload = address(new ProposalPayload());
    }

    function testProposal() public {
        address[] memory targets = new address[](1);
        targets[0] = proposalPayload;
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        string[] memory signatures = new string[](1);
        signatures[0] = "execute()";
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";
        bool[] memory withDelegatecalls = new bool[](1);
        withDelegatecalls[0] = true;

        uint256 proposalId = AaveGovHelpers._createProposal(
            vm,
            AAVE_WHALE,
            IAaveGov.SPropCreateParams({
                executor: AaveGovHelpers.SHORT_EXECUTOR,
                targets: targets,
                values: values,
                signatures: signatures,
                calldatas: calldatas,
                withDelegatecalls: withDelegatecalls,
                ipfsHash: bytes32(0)
            })
        );

        AaveGovHelpers._passVote(vm, AAVE_WHALE, proposalId);

        _validateAaveMerkleDistribution(proposalId);
        _validateLendTokenRescue(proposalId);
    }

    function _validateAaveMerkleTreeDistribution(uint256 proposalId) internal {
        IAaveGov.ProposalWithoutVotes memory proposalData = AaveGovHelpers
            ._getProposalById(proposalId);
        // Generally, there is no reason to have more than 1 payload if using the DELEGATECALL pattern
        address payload = proposalData.targets[0];
    
        // from payload get data;
        // address aaveMerkleDistributor = ProposalPayload(payload).
    }

    function _validateAaveMerkleDistributor(uint256 proposalId) internal {
        IAaveGov.ProposalWithoutVotes memory proposalData = AaveGovHelpers
            ._getProposalById(proposalId);
        address payload = proposalData.targets[0];
    }
}