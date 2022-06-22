// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "forge-std/Test.sol";
import { Executor } from "../contracts/LongExecutor.sol";
import { ProposalPayloadLongExecutor } from "../contracts/ProposalPayloadLongExecutor.sol";

contract DeployEcosystemReserve is Test {
    address public constant ADMIN = 0xEC568fffba86c094cf06b22134B23074DFE2252c; // Aave Governance
    uint256 public constant DELAY = 604800;
    uint256 public constant GRACE_PERIOD = 432000;
    uint256 public constant MINIMUM_DELAY = 604800;
    uint256 public constant MAXIMUM_DELAY = 864000;
    uint256 public constant PROPOSITION_THRESHOLD = 200;
    uint256 public constant VOTING_DURATION = 64000;
    uint256 public constant VOTE_DIFFERENTIAL = 1500;
    uint256 public constant MINIMUM_QUORUM = 1200; // TODO: set correct quorum before deploy

    function run() public {
        vm.startBroadcast();

        // deploy reserve ecosystem proposal payload
        Executor longExecutor = new Executor(
            ADMIN,
            DELAY,
            GRACE_PERIOD,
            MINIMUM_DELAY,
            MAXIMUM_DELAY,
            PROPOSITION_THRESHOLD,
            VOTING_DURATION,
            VOTE_DIFFERENTIAL,
            MINIMUM_QUORUM
        );
        console.log("longExecutor:", address(longExecutor));

        ProposalPayloadLongExecutor payload = new ProposalPayloadLongExecutor(
            address(longExecutor)
        );
        console.log("ProposalPayloadLongExecutor:", address(payload));

        vm.stopBroadcast();
    }
}
