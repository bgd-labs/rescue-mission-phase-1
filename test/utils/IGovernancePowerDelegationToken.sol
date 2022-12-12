// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovernancePowerDelegationToken {
  enum DelegationType {VOTING_POWER, PROPOSITION_POWER}

  /**
   * @dev delegates the specific power to a delegatee
   * @param delegatee the user which delegated power has changed
   * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
   **/
  function delegateByType(address delegatee, DelegationType delegationType) external virtual;

  /**
   * @dev returns the current delegated power of a user. The current power is the
   * power delegated at the time of the last snapshot
   * @param user the user
   **/
  function getPowerCurrent(address user, DelegationType delegationType)
  external
  virtual
  view
  returns (uint256);
}