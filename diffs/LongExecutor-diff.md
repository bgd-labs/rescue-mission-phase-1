```diff --git a/./etherscan/Executor/Executor.sol b/./src/contracts/LongExecutor.sol
index 01c891e..86e41d8 100644
--- a/./etherscan/Executor/Executor.sol
+++ b/./src/contracts/LongExecutor.sol
@@ -1,3 +1,7 @@
+/**
+ *Submitted for verification at Etherscan.io on 2020-12-10
+*/
+
 // SPDX-License-Identifier: agpl-3.0
 pragma solidity 0.7.5;
 pragma abicoder v2;
@@ -922,7 +926,30 @@ contract ExecutorWithTimelock is IExecutorWithTimelock {
   receive() external payable {}
 }
 
-interface IProposalValidator {
+interface IExecutor {
+  /**
+  * @dev method tu update the voting duration of the proposal
+  * @param votingDuration duration of the vote
+  */
+  function updateVotingDuration(uint256 votingDuration) external;
+
+  /**
+  * @dev method to update the vote differential needed to pass the proposal
+  * @param voteDifferential differential needed on the votes to pass the proposal
+  */
+  function updateVoteDifferential(uint256 voteDifferential) external;
+
+  /**
+  * @dev method to update the minimum quorum needed to pass the proposal
+  * @param minimumQuorum quorum needed to pass the proposal 
+  */
+  function updateMinimumQuorum(uint256 minimumQuorum) external;
+  /**
+    * @dev method to update the propositionThreshold
+    * @param propositionThreshold new proposition threshold
+    **/
+  function updatePropositionThreshold(uint256 propositionThreshold) external;
+
   /**
    * @dev Called to validate a proposal (e.g when creating new proposal in Governance)
    * @param governance Governance Contract
@@ -1049,26 +1076,28 @@ interface IProposalValidator {
 }
 
 /**
- * @title Proposal Validator Contract, inherited by  Aave Governance Executors
- * @dev Validates/Invalidations propositions state modifications.
- * Proposition Power functions: Validates proposition creations/ cancellation
- * Voting Power functions: Validates success of propositions.
+ * @title Time Locked, Validator, Executor Contract
+ * @dev Contract
+ * - Validate Proposal creations/ cancellation
+ * - Proposition Power functions: Validates proposition creations/ cancellation
+ * - Voting Power functions: Validates success of propositions.
+ * - Queue, Execute, Cancel, successful proposals' transactions.
  * @author Aave
  **/
-contract ProposalValidator is IProposalValidator {
+contract Executor is ExecutorWithTimelock, IExecutor {
   using SafeMath for uint256;
 
-  uint256 public immutable override PROPOSITION_THRESHOLD;
-  uint256 public immutable override VOTING_DURATION;
-  uint256 public immutable override VOTE_DIFFERENTIAL;
-  uint256 public immutable override MINIMUM_QUORUM;
+  uint256 public override PROPOSITION_THRESHOLD;
+  uint256 public override VOTING_DURATION;
+  uint256 public override VOTE_DIFFERENTIAL;
+  uint256 public override MINIMUM_QUORUM;
   uint256 public constant override ONE_HUNDRED_WITH_PRECISION = 10000; // Equivalent to 100%, but scaled for precision
 
-  /**
+    /**
    * @dev Constructor
    * @param propositionThreshold minimum percentage of supply needed to submit a proposal
    * - In ONE_HUNDRED_WITH_PRECISION units
-   * @param votingDuration duration in blocks of the voting period
+   * @param voteDuration duration in blocks of the voting period
    * @param voteDifferential percentage of supply that `for` votes need to be over `against`
    *   in order for the proposal to pass
    * - In ONE_HUNDRED_WITH_PRECISION units
@@ -1076,24 +1105,30 @@ contract ProposalValidator is IProposalValidator {
    * - In ONE_HUNDRED_WITH_PRECISION units
    **/
   constructor(
+    address admin,
+    uint256 delay,
+    uint256 gracePeriod,
+    uint256 minimumDelay,
+    uint256 maximumDelay,
     uint256 propositionThreshold,
-    uint256 votingDuration,
+    uint256 voteDuration,
     uint256 voteDifferential,
     uint256 minimumQuorum
-  ) {
+  )
+    ExecutorWithTimelock(admin, delay, gracePeriod, minimumDelay, maximumDelay)
+  {
     PROPOSITION_THRESHOLD = propositionThreshold;
-    VOTING_DURATION = votingDuration;
+    VOTING_DURATION = voteDuration;
     VOTE_DIFFERENTIAL = voteDifferential;
     MINIMUM_QUORUM = minimumQuorum;
   }
 
-  /**
-   * @dev Called to validate a proposal (e.g when creating new proposal in Governance)
-   * @param governance Governance Contract
-   * @param user Address of the proposal creator
-   * @param blockNumber Block Number against which to make the test (e.g proposal creation block -1).
-   * @return boolean, true if can be created
-   **/
+  /// @inheritdoc IExecutor
+  function updatePropositionThreshold(uint256 propositionThreshold) external override onlyAdmin {
+    PROPOSITION_THRESHOLD = propositionThreshold;
+  }
+   
+  /// @inheritdoc IExecutor
   function validateCreatorOfProposal(
     IAaveGovernanceV2 governance,
     address user,
@@ -1102,14 +1137,7 @@ contract ProposalValidator is IProposalValidator {
     return isPropositionPowerEnough(governance, user, blockNumber);
   }
 
-  /**
-   * @dev Called to validate the cancellation of a proposal
-   * Needs to creator to have lost proposition power threashold
-   * @param governance Governance Contract
-   * @param user Address of the proposal creator
-   * @param blockNumber Block Number against which to make the test (e.g proposal creation block -1).
-   * @return boolean, true if can be cancelled
-   **/
+  /// @inheritdoc IExecutor
   function validateProposalCancellation(
     IAaveGovernanceV2 governance,
     address user,
@@ -1118,13 +1146,7 @@ contract ProposalValidator is IProposalValidator {
     return !isPropositionPowerEnough(governance, user, blockNumber);
   }
 
-  /**
-   * @dev Returns whether a user has enough Proposition Power to make a proposal.
-   * @param governance Governance Contract
-   * @param user Address of the user to be challenged.
-   * @param blockNumber Block Number against which to make the challenge.
-   * @return true if user has enough power
-   **/
+  /// @inheritdoc IExecutor
   function isPropositionPowerEnough(
     IAaveGovernanceV2 governance,
     address user,
@@ -1138,12 +1160,7 @@ contract ProposalValidator is IProposalValidator {
       getMinimumPropositionPowerNeeded(governance, blockNumber);
   }
 
-  /**
-   * @dev Returns the minimum Proposition Power needed to create a proposition.
-   * @param governance Governance Contract
-   * @param blockNumber Blocknumber at which to evaluate
-   * @return minimum Proposition Power needed
-   **/
+  /// @inheritdoc IExecutor
   function getMinimumPropositionPowerNeeded(IAaveGovernanceV2 governance, uint256 blockNumber)
     public
     view
@@ -1160,12 +1177,7 @@ contract ProposalValidator is IProposalValidator {
         .div(ONE_HUNDRED_WITH_PRECISION);
   }
 
-  /**
-   * @dev Returns whether a proposal passed or not
-   * @param governance Governance Contract
-   * @param proposalId Id of the proposal to set
-   * @return true if proposal passed
-   **/
+  /// @inheritdoc IExecutor
   function isProposalPassed(IAaveGovernanceV2 governance, uint256 proposalId)
     external
     view
@@ -1176,11 +1188,7 @@ contract ProposalValidator is IProposalValidator {
       isVoteDifferentialValid(governance, proposalId));
   }
 
-  /**
-   * @dev Calculates the minimum amount of Voting Power needed for a proposal to Pass
-   * @param votingSupply Total number of oustanding voting tokens
-   * @return voting power needed for a proposal to pass
-   **/
+  /// @inheritdoc IExecutor
   function getMinimumVotingPowerNeeded(uint256 votingSupply)
     public
     view
@@ -1190,13 +1198,7 @@ contract ProposalValidator is IProposalValidator {
     return votingSupply.mul(MINIMUM_QUORUM).div(ONE_HUNDRED_WITH_PRECISION);
   }
 
-  /**
-   * @dev Check whether a proposal has reached quorum, ie has enough FOR-voting-power
-   * Here quorum is not to understand as number of votes reached, but number of for-votes reached
-   * @param governance Governance Contract
-   * @param proposalId Id of the proposal to verify
-   * @return voting power needed for a proposal to pass
-   **/
+  /// @inheritdoc IExecutor
   function isQuorumValid(IAaveGovernanceV2 governance, uint256 proposalId)
     public
     view
@@ -1211,13 +1213,7 @@ contract ProposalValidator is IProposalValidator {
     return proposal.forVotes >= getMinimumVotingPowerNeeded(votingSupply);
   }
 
-  /**
-   * @dev Check whether a proposal has enough extra FOR-votes than AGAINST-votes
-   * FOR VOTES - AGAINST VOTES > VOTE_DIFFERENTIAL * voting supply
-   * @param governance Governance Contract
-   * @param proposalId Id of the proposal to verify
-   * @return true if enough For-Votes
-   **/
+  /// @inheritdoc IExecutor
   function isVoteDifferentialValid(IAaveGovernanceV2 governance, uint256 proposalId)
     public
     view
@@ -1235,28 +1231,3 @@ contract ProposalValidator is IProposalValidator {
       ));
   }
 }
\ No newline at end of file
-
-/**
- * @title Time Locked, Validator, Executor Contract
- * @dev Contract
- * - Validate Proposal creations/ cancellation
- * - Validate Vote Quorum and Vote success on proposal
- * - Queue, Execute, Cancel, successful proposals' transactions.
- * @author Aave
- **/
-contract Executor is ExecutorWithTimelock, ProposalValidator {
-  constructor(
-    address admin,
-    uint256 delay,
-    uint256 gracePeriod,
-    uint256 minimumDelay,
-    uint256 maximumDelay,
-    uint256 propositionThreshold,
-    uint256 voteDuration,
-    uint256 voteDifferential,
-    uint256 minimumQuorum
-  )
-    ExecutorWithTimelock(admin, delay, gracePeriod, minimumDelay, maximumDelay)
-    ProposalValidator(propositionThreshold, voteDuration, voteDifferential, minimumQuorum)
-  {}
-}
\ No newline at end of file
