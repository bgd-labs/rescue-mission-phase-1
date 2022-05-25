// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

import {IERC20} from "./dependencies/openZeppelin/IERC20.sol";
import {VersionedInitializable} from "./dependencies/upgradeability/VersionedInitializable.sol";

/**
* @title LendToAaveMigrator
* @notice This contract implements the migration from LEND to AAVE token
* @author Aave 
*/
contract LendToAaveMigrator is VersionedInitializable {
    IERC20 public immutable AAVE;
    IERC20 public immutable LEND;
    uint256 public immutable LEND_AAVE_RATIO;
    uint256 public constant REVISION = 2;
    
    uint256 public _totalLendMigrated;

    /**
    * @dev emitted on migration
    * @param sender the caller of the migration
    * @param amount the amount being migrated
    */
    event LendMigrated(address indexed sender, uint256 indexed amount);

    /**
    * @dev emitted on token rescue when initializing
    * @param from the origin of the rescued funds
    * @param to the destination of the rescued funds
    * @param amount the amount being rescued
    */
    event AaveTokensRescued(address from, address indexed to, uint256 amount);

    /**
    * @param aave the address of the AAVE token
    * @param lend the address of the LEND token
    * @param lendAaveRatio the exchange rate between LEND and AAVE 
     */
    constructor(IERC20 aave, IERC20 lend, uint256 lendAaveRatio) public {
        AAVE = aave;
        LEND = lend;
        LEND_AAVE_RATIO = lendAaveRatio;
    }

    /**
    * @dev initializes the implementation
    */
    function initialize(address aaveMerkleDistributor, uint256 aaveAmount, uint256 lendAmount) public initializer {
        // account for the LEND sent to the contract for the total miggration
        _totalLendMigrated = _totalLendMigrated.add(lendAmount);

        // transfer AAVE + LEND sent to this contract
        uint256 amountToRescue = aaveAmount+lendAmount.div(LEND_AAVE_RATIO);
        AAVE.safeTransfer(aaveMerkleDistributor, amountToRescue);

        emit LendMigrated(address(this), lendAmount);

        emit AaveTokensRescued(address(this), aaveMerkleDistributor, amountToRescue);

        uint256 lendAmountToBurn = LEND.balanceOf(address(this));
        LEND.transfer(address(0), lendAmountToBurn);
    }

    /**
    * @dev returns true if the migration started
    */
    function migrationStarted() external view returns(bool) {
        return lastInitializedRevision != 0;
    }


    /**
    * @dev executes the migration from LEND to AAVE. Users need to give allowance to this contract to transfer LEND before executing
    * this transaction.
    * @param amount the amount of LEND to be migrated
    */
    function migrateFromLEND(uint256 amount) external {
        require(lastInitializedRevision != 0, "MIGRATION_NOT_STARTED");

        _totalLendMigrated = _totalLendMigrated.add(amount);
        LEND.transferFrom(msg.sender, address(this), amount);
        AAVE.transfer(msg.sender, amount.div(LEND_AAVE_RATIO));
        emit LendMigrated(msg.sender, amount);
    }

    /**
    * @dev returns the implementation revision
    * @return the implementation revision
    */
    function getRevision() internal pure override returns (uint256) {
        return REVISION;
    }
}