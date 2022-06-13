```diff --git a/./etherscan/Executor/Executor.sol b/./src/contracts/LongExecutor.sol
index 01c891e..5c21f78 100644
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
 
@@ -1058,10 +1058,10 @@ interface IProposalValidator {
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
@@ -1236,6 +1236,41 @@ contract ProposalValidator is IProposalValidator {
   }
 }
 
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
+
+  // event triggered when voting duration gets updated by the admin
+  event VotingDurationUpdated(address indexed executor, address indexed admin, uint256 oldVotingDuration, uint256 newVotingDuration);
+  // event triggered when vote differential gets updated by the admin
+  event VoteDifferentialUpdated(address indexed executor, address indexed admin, uint256 oldVoteDifferential, uint256 newVoteDifferential);
+  // event triggered when minimum quorum gets updated by the admin
+  event MinimumQuorumUpdated(address indexed executor, address indexed admin, uint256 oldMinimumQuorum, uint256 newMinimumQuorum);
+  // event triggered when proposition threshold gets updated by the admin
+  event PropositionThresholdUpdated(address indexed executor, address indexed admin, uint256 oldPropositionThreshold, uint256 newPropositionThreshold);
+}
+
 /**
  * @title Time Locked, Validator, Executor Contract
  * @dev Contract
@@ -1244,7 +1279,7 @@ contract ProposalValidator is IProposalValidator {
  * - Queue, Execute, Cancel, successful proposals' transactions.
  * @author Aave
  **/
-contract Executor is ExecutorWithTimelock, ProposalValidator {
+contract Executor is ExecutorWithTimelock, ProposalValidator, IExecutor {
   constructor(
     address admin,
     uint256 delay,
@@ -1259,4 +1294,32 @@ contract Executor is ExecutorWithTimelock, ProposalValidator {
     ExecutorWithTimelock(admin, delay, gracePeriod, minimumDelay, maximumDelay)
     ProposalValidator(propositionThreshold, voteDuration, voteDifferential, minimumQuorum)
   {}
+
+  /// @inheritdoc IExecutor
+  function updateVotingDuration(uint256 votingDuration) external override onlyAdmin {
+    uint256 oldVotingDuration = VOTING_DURATION;
+    VOTING_DURATION = votingDuration;
+    emit VotingDurationUpdated(address(this), getAdmin(), oldVotingDuration, VOTING_DURATION);
+  }
+  
+  /// @inheritdoc IExecutor
+  function updateVoteDifferential(uint256 voteDifferential) external override onlyAdmin {
+    uint256 oldVoteDifferential = VOTE_DIFFERENTIAL;
+    VOTE_DIFFERENTIAL = voteDifferential;
+    emit VoteDifferentialUpdated(address(this), getAdmin(), oldVoteDifferential, VOTE_DIFFERENTIAL);
+  }
+
+  /// @inheritdoc IExecutor
+  function updateMinimumQuorum(uint256 minimumQuorum) external override onlyAdmin {
+    uint256 oldMinimumQuorum = MINIMUM_QUORUM;
+    MINIMUM_QUORUM = minimumQuorum;
+    emit MinimumQuorumUpdated(address(this), getAdmin(), oldMinimumQuorum, MINIMUM_QUORUM);
+  }
+
+  /// @inheritdoc IExecutor
+  function updatePropositionThreshold(uint256 propositionThreshold) external override onlyAdmin {
+    uint256 oldPropositionThreshold = PROPOSITION_THRESHOLD;
+    PROPOSITION_THRESHOLD = propositionThreshold;
+    emit PropositionThresholdUpdated(address(this), getAdmin(), oldPropositionThreshold, PROPOSITION_THRESHOLD);
+  }
 }
\ No newline at end of file
