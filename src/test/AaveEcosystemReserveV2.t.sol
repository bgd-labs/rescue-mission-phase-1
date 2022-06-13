// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import 'forge-std/Test.sol';
import {AaveEcosystemReserveV2} from '../contracts/AaveEcosystemReserveV2';


contract AaveEcosystemReserveV2 is Test {
  function setUp() public {}

  function testInitialization() public {}

  function testGovernanceVote() public {}


  // interanl method for test preparation
  // TODO: create a payload and then a proposal
  // should it be long or short?? check which executor is admin of ecosystem
  function _createMockProposal() internal {}
}