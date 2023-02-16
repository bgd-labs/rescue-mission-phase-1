```diff
diff --git a/reports/LendToAaveMigrator_layout.md b/reports/rescue_LendToAaveMigrator_layout.md
index d8e51d5..f51ac34 100644
--- a/reports/LendToAaveMigrator_layout.md
+++ b/reports/rescue_LendToAaveMigrator_layout.md
@@ -1,5 +1,5 @@
-| Name                    | Type        | Slot | Offset | Bytes | Contract                                                                               |
-|-------------------------|-------------|------|--------|-------|----------------------------------------------------------------------------------------|
-| lastInitializedRevision | uint256     | 0    | 0      | 32    | etherscan/LendToAaveMigrator/contracts/token/LendToAaveMigrator.sol:LendToAaveMigrator |
-| ______gap               | uint256[50] | 1    | 0      | 1600  | etherscan/LendToAaveMigrator/contracts/token/LendToAaveMigrator.sol:LendToAaveMigrator |
-| _totalLendMigrated      | uint256     | 51   | 0      | 32    | etherscan/LendToAaveMigrator/contracts/token/LendToAaveMigrator.sol:LendToAaveMigrator |
+| Name                    | Type        | Slot | Offset | Bytes | Contract                                                |
+|-------------------------|-------------|------|--------|-------|---------------------------------------------------------|
+| lastInitializedRevision | uint256     | 0    | 0      | 32    | src/contracts/LendToAaveMigrator.sol:LendToAaveMigrator |
+| ______gap               | uint256[50] | 1    | 0      | 1600  | src/contracts/LendToAaveMigrator.sol:LendToAaveMigrator |
+| _totalLendMigrated      | uint256     | 51   | 0      | 32    | src/contracts/LendToAaveMigrator.sol:LendToAaveMigrator |
```
