```diff --git a/./etherscan/LendToAaveMigrator/contracts/token/LendToAaveMigrator.sol b/./src/contracts/LendToAaveMigrator.sol
index e316261..6e6a51a 100644
--- a/./etherscan/LendToAaveMigrator/contracts/token/LendToAaveMigrator.sol
+++ b/./src/contracts/LendToAaveMigrator.sol
@@ -1,10 +1,8 @@
 // SPDX-License-Identifier: agpl-3.0
-pragma solidity 0.6.10;
-
-import {IERC20} from "../interfaces/IERC20.sol";
-import {SafeMath} from "../open-zeppelin/SafeMath.sol";
-import {VersionedInitializable} from "../utils/VersionedInitializable.sol";
+pragma solidity ^0.8.0;
 
+import {IERC20} from "solidity-utils/contracts/oz-common/interfaces/IERC20.sol";
+import {VersionedInitializable} from "./dependencies/upgradeability/VersionedInitializable.sol";
 
 /**
 * @title LendToAaveMigrator
@@ -12,12 +10,10 @@ import {VersionedInitializable} from "../utils/VersionedInitializable.sol";
 * @author Aave 
 */
 contract LendToAaveMigrator is VersionedInitializable {
-    using SafeMath for uint256;
-
     IERC20 public immutable AAVE;
     IERC20 public immutable LEND;
     uint256 public immutable LEND_AAVE_RATIO;
-    uint256 public constant REVISION = 1;
+    uint256 public constant REVISION = 2;
     
     uint256 public _totalLendMigrated;
 
@@ -28,6 +24,14 @@ contract LendToAaveMigrator is VersionedInitializable {
     */
     event LendMigrated(address indexed sender, uint256 indexed amount);
 
+    /**
+    * @dev emitted on token rescue when initializing
+    * @param from the origin of the rescued funds
+    * @param to the destination of the rescued funds
+    * @param amount the amount being rescued
+    */
+    event AaveTokensRescued(address from, address indexed to, uint256 amount);
+
     /**
     * @param aave the address of the AAVE token
     * @param lend the address of the LEND token
@@ -40,9 +44,30 @@ contract LendToAaveMigrator is VersionedInitializable {
     }
 
     /**
-    * @dev initializes the implementation
+    * @dev initializes the implementation and rescues the LEND sent to the contract
+    * by migrating them to AAVE and sending them to the AaveMerkleDistributor
+    * and then burning the LEND tokens
+    * @param aaveMerkleDistributor address of the AAVE rescue distributor
+    * @param lendAmount amount of lend that need to be rescued
     */
-    function initialize() public initializer {
+    function initialize(address aaveMerkleDistributor, uint256 lendAmount) public initializer {
+        // account for the LEND sent to the contract for the total migration
+        _totalLendMigrated = _totalLendMigrated + lendAmount;
+
+        // transfer AAVE + LEND sent to this contract
+        uint256 amountToRescue = lendAmount / LEND_AAVE_RATIO;
+        AAVE.transfer(aaveMerkleDistributor, amountToRescue);
+
+        uint256 lendAmountToBurn = LEND.balanceOf(address(this));
+        LEND.transfer(address(LEND), lendAmountToBurn);
+
+        emit LendMigrated(address(this), lendAmount);
+        emit AaveTokensRescued(address(this), aaveMerkleDistributor, amountToRescue);
+
+        // checks that the amount of Aave not migrated is less or equal than the amount Aave disposable for migration
+        require((LEND.totalSupply() - LEND.balanceOf(address(this)) - LEND.balanceOf(address(LEND)) ) / LEND_AAVE_RATIO <= AAVE.balanceOf(address(this)),
+            'INCORRECT_BALANCE_RESCUED'
+        );
     }
 
     /**
@@ -52,18 +77,21 @@ contract LendToAaveMigrator is VersionedInitializable {
         return lastInitializedRevision != 0;
     }
 
-
     /**
     * @dev executes the migration from LEND to AAVE. Users need to give allowance to this contract to transfer LEND before executing
     * this transaction.
+    * burns the migrated LEND amount 
     * @param amount the amount of LEND to be migrated
     */
     function migrateFromLEND(uint256 amount) external {
         require(lastInitializedRevision != 0, "MIGRATION_NOT_STARTED");
 
-        _totalLendMigrated = _totalLendMigrated.add(amount);
+        _totalLendMigrated = _totalLendMigrated + amount;
         LEND.transferFrom(msg.sender, address(this), amount);
-        AAVE.transfer(msg.sender, amount.div(LEND_AAVE_RATIO));
+        AAVE.transfer(msg.sender, amount / LEND_AAVE_RATIO);
+
+        LEND.transfer(address(LEND), amount);
+        
         emit LendMigrated(msg.sender, amount);
     }
 
@@ -74,5 +102,4 @@ contract LendToAaveMigrator is VersionedInitializable {
     function getRevision() internal pure override returns (uint256) {
         return REVISION;
     }
-
 }
\ No newline at end of file
