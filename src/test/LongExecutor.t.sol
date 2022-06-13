// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import 'forge-std/Test.sol';
import {Executor} from '../contracts/LongExecutor.sol';

contract LongExecutorTest is Test {
  address public constant ADMIN = address(1234);
  uint256 public constant DELAY = 604800;
  uint256 public constant GRACE_PERIOD = 432000;
  uint256 public constant MINIMUM_DELAY = 604800;
  uint256 public constant MAXIMUM_DELAY = 864000;
  uint256 public constant PROPOSITION_THRESHOLD = 200;
  uint256 public constant VOTING_DURATION = 64000;
  uint256 public constant VOTE_DIFFERENTIAL = 1500;
  uint256 public constant MINIMUM_QUORUM = 1200;

  Executor executor;

  // events
  event VotingDurationUpdated(address indexed executor, address indexed admin, uint256 oldVotingDuration, uint256 newVotingDuration);
  event VoteDifferentialUpdated(address indexed executor, address indexed admin, uint256 oldVoteDifferential, uint256 newVoteDifferential);
  event MinimumQuorumUpdated(address indexed executor, address indexed admin, uint256 oldMinimumQuorum, uint256 newMinimumQuorum);
  event PropositionThresholdUpdated(address indexed executor, address indexed admin, uint256 oldPropositionThreshold, uint256 newPropositionThreshold);
  
  function setUp() public {
    executor = new Executor(
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
  }

  function testContstructor() public {
    assertEq(ADMIN, executor.getAdmin());
    assertEq(DELAY, executor.getDelay());
    assertEq(GRACE_PERIOD, executor.GRACE_PERIOD());
    assertEq(MINIMUM_DELAY, executor.MINIMUM_DELAY());
    assertEq(MAXIMUM_DELAY, executor.MAXIMUM_DELAY());
    assertEq(PROPOSITION_THRESHOLD, executor.PROPOSITION_THRESHOLD());
    assertEq(VOTING_DURATION, executor.VOTING_DURATION());
    assertEq(VOTE_DIFFERENTIAL, executor.VOTE_DIFFERENTIAL());
    assertEq(MINIMUM_QUORUM, executor.MINIMUM_QUORUM());
  }

  function testUpdateVotingDuration() public {
    hoax(ADMIN);
    uint256 newVotingDuration = 54000;

    vm.expectEmit(true, true, false, true);
    emit VotingDurationUpdated(address(executor), ADMIN, VOTING_DURATION, newVotingDuration);

    executor.updateVotingDuration(newVotingDuration);

    assertEq(newVotingDuration, executor.VOTING_DURATION());
  }

  function testUpdateVotingDurationWhenNotAdmin() public {
    uint256 newVotingDuration = 54000;

    vm.expectRevert(bytes('ONLY_BY_ADMIN'));
    executor.updateVotingDuration(newVotingDuration);
  }

  function testUpdateVoteDifferential() public {
    hoax(ADMIN);
    uint256 newVoteDifferential = 2000;

    vm.expectEmit(true, true, false, true);
    emit VoteDifferentialUpdated(address(executor), ADMIN, VOTE_DIFFERENTIAL, newVoteDifferential);

    executor.updateVoteDifferential(newVoteDifferential);
    assertEq(newVoteDifferential, executor.VOTE_DIFFERENTIAL());
  }

  function testUpdateVoteDifferentialWhenNotAdmin() public {
    uint256 newVoteDifferential = 2000;
    vm.expectRevert(bytes('ONLY_BY_ADMIN'));
    executor.updateVoteDifferential(newVoteDifferential);
  }

  function testUpdateMinimumQuorum() public {
    hoax(ADMIN);
    uint256 newMinimumQuorum = 4000;

    vm.expectEmit(true, true, false, true);
    emit MinimumQuorumUpdated(address(executor), ADMIN, MINIMUM_QUORUM, newMinimumQuorum);

    executor.updateMinimumQuorum(newMinimumQuorum);
    assertEq(newMinimumQuorum, executor.MINIMUM_QUORUM());
  }

  function testUpdateMinimumQuorumWhenNotAdmin() public {
    uint256 newMinimumQuorum = 4000;
    vm.expectRevert(bytes('ONLY_BY_ADMIN'));
    executor.updateMinimumQuorum(newMinimumQuorum);
  }

  function testUpdatePropositionThreshold() public {
    hoax(ADMIN);
    uint256 newMinimumPropositionThreshold = 300;

    vm.expectEmit(true, true, false, true);
    emit PropositionThresholdUpdated(address(executor), ADMIN, PROPOSITION_THRESHOLD, newMinimumPropositionThreshold);

    executor.updatePropositionThreshold(newMinimumPropositionThreshold);
    assertEq(newMinimumPropositionThreshold, executor.PROPOSITION_THRESHOLD());
  }

  function testUpdatePropositionThresholdWhenNotAdmin() public {
    uint256 newMinimumPropositionThreshold = 300;
    vm.expectRevert(bytes('ONLY_BY_ADMIN'));
    executor.updatePropositionThreshold(newMinimumPropositionThreshold);
  }
}