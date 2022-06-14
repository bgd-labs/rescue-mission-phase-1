// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IInitializableAdminUpgradeabilityProxy } from "./interfaces/IInitializableAdminUpgradeabilityProxy.sol";
import { AaveEcosystemReserveV2 } from "./AaveEcosystemReserveV2.sol";

contract ProposalPayloadEcosystemReserve {
    address public immutable AAVE_ECOSYSTEM_RESERVE_V2_IMPL;
    address public immutable PROPOSAL_ID;
    address public constant AAVE_GOVERNANCE_V2 =
        0xEC568fffba86c094cf06b22134B23074DFE2252c;

    IInitializableAdminUpgradeabilityProxy public constant ECOSYSTEM_PROXY =
        IInitializableAdminUpgradeabilityProxy(
            0x25F2226B597E8F9514B3F68F00f494cF4f286491
        );

    constructor(address aaveEcosystemReserveV2Impl, uint256 proposalId) {
        AAVE_ECOSYSTEM_RESERVE_V2_IMPL = aaveEcosystemReserveV2Impl;
        PROPOSAL_ID = proposalId;
    }

    function execute() external {
        ECOSYSTEM_PROXY.upgradeToAndCall(
            AAVE_ECOSYSTEM_RESERVE_V2_IMPL,
            "initialize(uint256,address)",
            proposalId,
            AAVE_GOVERNANCE_V2
        );
    }
}
