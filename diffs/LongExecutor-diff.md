```diff --git a/./etherscan/Executor/Executor.sol b/./src/contracts/LongExecutor.sol
index 01c891e..4823bb7 100644
--- a/./etherscan/Executor/Executor.sol
+++ b/./src/contracts/LongExecutor.sol
@@ -867,7 +867,7 @@ contract ExecutorWithTimelock is IExecutorWithTimelock {
    * @dev Getter of the current admin address (should be governance)
    * @return The address of the current admin
    **/
-  function getAdmin() external view override returns (address) {
+  function getAdmin() public view override returns (address) {
     return _admin;
   }
 
@@ -923,6 +923,15 @@ contract ExecutorWithTimelock is IExecutorWithTimelock {
 }
 
 interface IProposalValidator {
+  // event triggered when voting duration gets updated by the admin
+  event VotingDurationUpdated(uint256 newVotingDuration);
+  // event triggered when vote differential gets updated by the admin
+  event VoteDifferentialUpdated(uint256 newVoteDifferential);
+  // event triggered when minimum quorum gets updated by the admin
+  event MinimumQuorumUpdated(uint256 newMinimumQuorum);
+  // event triggered when proposition threshold gets updated by the admin
+  event PropositionThresholdUpdated(uint256 newPropositionThreshold);
+  
   /**
    * @dev Called to validate a proposal (e.g when creating new proposal in Governance)
    * @param governance Governance Contract
@@ -1058,10 +1067,10 @@ interface IProposalValidator {
 contract ProposalValidator is IProposalValidator {
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
 
   /**
@@ -1081,10 +1090,10 @@ contract ProposalValidator is IProposalValidator {
     uint256 voteDifferential,
     uint256 minimumQuorum
   ) {
-    PROPOSITION_THRESHOLD = propositionThreshold;
-    VOTING_DURATION = votingDuration;
-    VOTE_DIFFERENTIAL = voteDifferential;
-    MINIMUM_QUORUM = minimumQuorum;
+    _updateVotingDuration(votingDuration);
+    _updateVoteDifferential(voteDifferential);
+    _updateMinimumQuorum(minimumQuorum);
+    _updatePropositionThreshold(propositionThreshold);
   }
 
   /**
@@ -1234,6 +1243,56 @@ contract ProposalValidator is IProposalValidator {
         VOTE_DIFFERENTIAL
       ));
   }
+
+  /// updates voting duration
+  function _updateVotingDuration(uint256 votingDuration) internal {
+    VOTING_DURATION = votingDuration;
+    emit VotingDurationUpdated(VOTING_DURATION);
+  }
+
+  /// updates vote differential
+  function _updateVoteDifferential(uint256 voteDifferential) internal {
+    VOTE_DIFFERENTIAL = voteDifferential;
+    emit VoteDifferentialUpdated(VOTE_DIFFERENTIAL);
+  }
+
+  /// updates minimum quorum
+  function _updateMinimumQuorum(uint256 minimumQuorum) internal {
+    MINIMUM_QUORUM = minimumQuorum;
+    emit MinimumQuorumUpdated(MINIMUM_QUORUM);
+  }
+
+  /// updates proposition threshold
+  function _updatePropositionThreshold(uint256 propositionThreshold) internal {
+    PROPOSITION_THRESHOLD = propositionThreshold;
+    emit PropositionThresholdUpdated(PROPOSITION_THRESHOLD);
+  }
+}
+
+
+interface IExecutor {
+  /**
+  * @dev method tu update the voting duration of the proposal. Only callable by admin.
+  * @param votingDuration duration of the vote
+  */
+  function updateVotingDuration(uint256 votingDuration) external;
+
+  /**
+  * @dev method to update the vote differential needed to pass the proposal. Only callable by admin.
+  * @param voteDifferential differential needed on the votes to pass the proposal
+  */
+  function updateVoteDifferential(uint256 voteDifferential) external;
+
+  /**
+  * @dev method to update the minimum quorum needed to pass the proposal. Only callable by admin.
+  * @param minimumQuorum quorum needed to pass the proposal 
+  */
+  function updateMinimumQuorum(uint256 minimumQuorum) external;
+  /**
+    * @dev method to update the propositionThreshold. Only callable by admin.
+    * @param propositionThreshold new proposition threshold
+    **/
+  function updatePropositionThreshold(uint256 propositionThreshold) external;
 }
 
 /**
@@ -1244,7 +1303,7 @@ contract ProposalValidator is IProposalValidator {
  * - Queue, Execute, Cancel, successful proposals' transactions.
  * @author Aave
  **/
-contract Executor is ExecutorWithTimelock, ProposalValidator {
+contract Executor is ExecutorWithTimelock, ProposalValidator, IExecutor {
   constructor(
     address admin,
     uint256 delay,
@@ -1259,4 +1318,24 @@ contract Executor is ExecutorWithTimelock, ProposalValidator {
     ExecutorWithTimelock(admin, delay, gracePeriod, minimumDelay, maximumDelay)
     ProposalValidator(propositionThreshold, voteDuration, voteDifferential, minimumQuorum)
   {}
+
+  /// @inheritdoc IExecutor
+  function updateVotingDuration(uint256 votingDuration) external override onlyAdmin {
+    _updateVotingDuration(votingDuration);
+  }
+  
+  /// @inheritdoc IExecutor
+  function updateVoteDifferential(uint256 voteDifferential) external override onlyAdmin {
+    _updateVoteDifferential(voteDifferential);
+  }
+
+  /// @inheritdoc IExecutor
+  function updateMinimumQuorum(uint256 minimumQuorum) external override onlyAdmin {
+    _updateMinimumQuorum(minimumQuorum);
+  }
+
+  /// @inheritdoc IExecutor
+  function updatePropositionThreshold(uint256 propositionThreshold) external override onlyAdmin {
+    _updatePropositionThreshold(propositionThreshold);
+  }
 }
\ No newline at end of file
