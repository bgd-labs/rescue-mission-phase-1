// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IERC20} from "../contracts/dependencies/openZeppelin/IERC20.sol";
import {AaveMerkleDistributor} from "../contracts/AaveMerkleDistributor.sol";
import {ProposalPayloadLong} from "../contracts/ProposalPayloadLong.sol";
import {AaveGovHelpers, IAaveGov} from "./utils/AaveGovHelpers.sol";


contract ProposalPayloadLongTest is Test {
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address internal constant AAVE_WHALE = address(0x25F2226B597E8F9514B3F68F00f494cF4f286491);
    address internal constant AAVE_WHALE2 = address(0x4da27a545c0c5B758a6BA100e3a049001de870f5);
    
    ProposalPayloadLong internal proposalPayload;

    function setUp() public {
        _prepareWhale();

        AaveMerkleDistributor aaveMerkleDistributor = new AaveMerkleDistributor();
    
        // give ownership of distributor to short executor
        aaveMerkleDistributor.transferOwnership(AaveGovHelpers.SHORT_EXECUTOR);

        proposalPayload = new ProposalPayloadLong(address(aaveMerkleDistributor));

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

        uint256 proposalId = AaveGovHelpers._createProposal(
            vm,
            AAVE_WHALE,
            IAaveGov.SPropCreateParams({
                executor: AaveGovHelpers.LONG_EXECUTOR,
                targets: targets,
                values: values,
                signatures: signatures,
                calldatas: calldatas,
                withDelegatecalls: withDelegatecalls,
                ipfsHash: bytes32(0)
            })
        );

        console.log('balance ', IERC20(AAVE).balanceOf(AAVE_WHALE));
        AaveGovHelpers._passVote(vm, AAVE_WHALE, proposalId);

        _validateAaveContractTokensRescued(proposalId);
    }

    function _validateAaveContractTokensRescued(uint256 proposalId) internal {
        IAaveGov.ProposalWithoutVotes memory proposalData = AaveGovHelpers
            ._getProposalById(proposalId);
        // Generally, there is no reason to have more than 1 payload if using the DELEGATECALL pattern
        address payload = proposalData.targets[0];
    
        // from payload get data;
        ProposalPayloadLong proposalPayload = ProposalPayloadLong(payload);

        address aaveMerkleDistributor = address(AaveMerkleDistributor(proposalPayload.AAVE_MERKLE_DISTRIBUTOR()));

        assertEq(
            IERC20(proposalPayload.AAVE_TOKEN()).balanceOf(aaveMerkleDistributor),
            proposalPayload.AAVE_RESCUE_AMOUNT()
        );
        assertEq(
            IERC20(proposalPayload.USDT_TOKEN()).balanceOf(aaveMerkleDistributor),
            proposalPayload.USDT_RESCUE_AMOUNT()
        );
        assertEq(
            IERC20(proposalPayload.UNI_TOKEN()).balanceOf(aaveMerkleDistributor),
            proposalPayload.UNI_RESCUE_AMOUNT()
        );
        
    }

    function _prepareWhale() internal {
        deal(AAVE, address(this), 4000000 ether);
        deal(address(this), 1 ether);
        IERC20(AAVE).transfer(AAVE_WHALE, 3000000 ether);
    }
}