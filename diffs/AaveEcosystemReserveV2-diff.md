```diff --git a/./etherscan/AaveEcosystemReserveV2/AaveEcosystemReserveV2.sol b/./src/contracts/AaveEcosystemReserveV2.sol
index 2df2421..197685b 100644
--- a/./etherscan/AaveEcosystemReserveV2/AaveEcosystemReserveV2.sol
+++ b/./src/contracts/AaveEcosystemReserveV2.sol
@@ -1,3 +1,7 @@
+/**
+ *Submitted for verification at Etherscan.io on 2022-05-02
+*/
+
 // SPDX-License-Identifier: GPL-3.0
 pragma solidity 0.8.11;
 
@@ -188,6 +192,9 @@ interface IAdminControlledEcosystemReserve {
         uint256 amount
     ) external;
 }
+interface IAaveGovernanceV2 {
+    function submitVote(uint256 proposalId, bool support) external;
+}
 /**
  * @title VersionedInitializable
  *
@@ -660,7 +667,7 @@ abstract contract AdminControlledEcosystemReserve is
 
     address internal _fundsAdmin;
 
-    uint256 public constant REVISION = 4;
+    uint256 public constant REVISION = 5;
 
     /// @inheritdoc IAdminControlledEcosystemReserve
     address public constant ETH_MOCK_ADDRESS =
@@ -714,7 +721,6 @@ abstract contract AdminControlledEcosystemReserve is
 }
 
 
-
 /**
  * @title AaveEcosystemReserve v2
  * @notice Stores ERC20 tokens of an ecosystem reserve, adding streaming capabilities.
@@ -769,10 +775,17 @@ contract AaveEcosystemReserveV2 is
     }
 
     /*** Contract Logic Starts Here */
-
-    function initialize(address fundsAdmin) external initializer {
-        _nextStreamId = 100000;
-        _setFundsAdmin(fundsAdmin);
+    // TODO: initialize with logic to vote
+    function initialize(uint256 proposalId, address aaveGovernanceV2) external initializer {
+        // comented as alread initialized with, in older version
+        // _nextStreamId = 100000;
+        // _setFundsAdmin(fundsAdmin);
+
+        // voting process
+        IAaveGovernanceV2 aaveGov = IAaveGovernanceV2(aaveGovernanceV2);
+        // TODO: do we need to check if proposal exists, if its in correct state, etc etc?
+        // or just let it fail if not?
+        aaveGov.submitVote(proposalId, true);
     }
 
     /*** View Functions ***/
