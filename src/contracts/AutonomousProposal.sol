pragma solidity ^0.8.0;

import { AaveGovernanceV2, IExecutorWithTimelock, IGovernanceStrategy } from "aave-address-book/AaveGovernanceV2.sol";
import { IERC20 } from "solidity-utils/contracts/oz-common/interfaces/IERC20.sol";
import { SafeERC20 } from 'solidity-utils/contracts/oz-common/SafeERC20.sol';

contract AutonomousProposal {
    using SafeERC20 for IERC20;

    uint256 public constant GRACE_PERIOD = 5 days;

    address public immutable PAYLOAD_SHORT;
    address public immutable PAYLOAD_LONG;

    bytes32 public immutable SHORT_PAYLOAD_IPFS;
    bytes32 public immutable LONG_PAYLOAD_IPFS;

    uint256 public immutable PROPOSALS_CREATION_TIMESTAMP;

    uint256 public longExecutorProposalId;
    uint256 public shortExecutorProposalId;

    event ProposalsCreated(
        address executor,
        uint256 longExecutorProposalId,
        uint256 shortExecutorProposalId,
        address longExecutorPayload,
        bytes32 longIpfsHash,
        address shortExecutorPayload,
        bytes32 shortIpfsHash
    );

    constructor(
        address payloadShort,
        address payloadLong,
        bytes32 payloadShortIpfs,
        bytes32 payloadLongIpfs,
        uint256 creationTimestamp
    ) {
        require(payloadShort != address(0), "SHORT_PAYLOAD_ADDRESS_0");
        require(
            payloadShortIpfs != bytes32(0),
            "SHORT_PAYLOAD_IPFS_HASH_BYTES32_0"
        );
        require(payloadLong != address(0), "LONG_PAYLOAD_ADDRESS_0");
        require(
            payloadLongIpfs != bytes32(0),
            "LONG_PAYLOAD_IPFS_HASH_BYTES32_0"
        );
        require(
            creationTimestamp > block.timestamp,
            "CREATION_TIMESTAMP_TO_EARLY"
        );

        PAYLOAD_LONG = payloadLong;
        PAYLOAD_SHORT = payloadShort;
        SHORT_PAYLOAD_IPFS = payloadShortIpfs;
        LONG_PAYLOAD_IPFS = payloadLongIpfs;
        PROPOSALS_CREATION_TIMESTAMP = creationTimestamp;
    }

    function createProposals() external {
        require(
            longExecutorProposalId == 0 && shortExecutorProposalId == 0,
            "PROPOSALS_ALREADY_CREATED"
        );
        require(
            block.timestamp > PROPOSALS_CREATION_TIMESTAMP,
            "CREATION_TIMESTAMP_NOT_YET_REACHED"
        );
        require(
            block.timestamp < PROPOSALS_CREATION_TIMESTAMP + GRACE_PERIOD,
            "TIMESTAMP_BIGGER_THAN_GRACE_PERIOD"
        );

        longExecutorProposalId = _createProposal(
            PAYLOAD_LONG,
            LONG_PAYLOAD_IPFS,
            AaveGovernanceV2.LONG_EXECUTOR
        );

        shortExecutorProposalId = _createProposal(
            PAYLOAD_SHORT,
            SHORT_PAYLOAD_IPFS,
            AaveGovernanceV2.SHORT_EXECUTOR
        );

        emit ProposalsCreated(
            msg.sender,
            longExecutorProposalId,
            shortExecutorProposalId,
            PAYLOAD_LONG,
            LONG_PAYLOAD_IPFS,
            PAYLOAD_SHORT,
            SHORT_PAYLOAD_IPFS
        );
    }

    /// @dev method to vote on the governance proposals, in case there is some
    /// voting power delegation by error
    function voteOnProposals() external {
        require(
            longExecutorProposalId != 0 && shortExecutorProposalId != 0,
            "PROPOSALS_NOT_CREATED"
        );
        AaveGovernanceV2.GOV.submitVote(longExecutorProposalId, true);
        AaveGovernanceV2.GOV.submitVote(shortExecutorProposalId, true);
    }

    function emergencyTokenTransfer(
        address erc20Token,
        address to,
        uint256 amount
    ) external {
        require(
            msg.sender == AaveGovernanceV2.SHORT_EXECUTOR,
            "CALLER_NOT_EXECUTOR"
        );
        IERC20(erc20Token).safeTransfer(to, amount);
    }

    function _createProposal(
        address payload,
        bytes32 ipfsHash,
        address executor
    ) internal returns (uint256) {
        address[] memory targets = new address[](1);
        targets[0] = payload;
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        string[] memory signatures = new string[](1);
        signatures[0] = "execute()";
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";
        bool[] memory withDelegatecalls = new bool[](1);
        withDelegatecalls[0] = true;

        return
            AaveGovernanceV2.GOV.create(
                IExecutorWithTimelock(executor),
                targets,
                values,
                signatures,
                calldatas,
                withDelegatecalls,
                ipfsHash
            );
    }
}
