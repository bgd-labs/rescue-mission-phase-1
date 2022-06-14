// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { ProposalPayloadAaveEcosystemReserveV2 } from "../contracts/ProposalPayloadAaveEcosystemReserveV2.sol";
import { AaveGovHelpers, IAaveGov } from "./utils/AaveGovHelpers.sol";
import { AaveEcosystemReserveV2 } from "../contracts/AaveEcosystemReserveV2.sol";

contract ProposalPayloadAaveEcosystemReserveV2Test is Test {
    address internal constant AAVE_WHALE =
        address(0x25F2226B597E8F9514B3F68F00f494cF4f286491);
    
    uint256 public proposalId;


    function setUp() public {}

}