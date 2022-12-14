// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IAaveMerkleDistributor {
    /// @dev struct that contains the information for a distributionId id
    /// @param merkleRoot the merkle root of the merkle tree containing account balances available to claim.
    /// @param claimedBitMap containing the address index to claimed bool. 
    //       This works by storing the indexes 0-255 as 0, 256-511 as 1.
    //       It is using the bit representation of uint256 to save on gas.
    struct Distribution {
        address token;
        bytes32 merkleRoot;
        mapping(uint256 => uint256) claimedBitMap;
    }

    /// @dev distribution information structure without the claim bitmap for usage as return object
    struct DistributionWithoutClaimed {
        address token;
        bytes32 merkleRoot;
    }

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address indexed account, uint256 amount, uint256 indexed distributionId);
    // this event is triggered when adding a new distribution
    event DistributionAdded(address indexed token, bytes32 indexed merkleRoot, uint256 indexed distributionId);
    
    /**
    * @dev returns the token and merkleRoot of a distirbution id
    * @param distributionId id of the distribution we want the information of
    */
    function getDistribution(uint256 distributionId) external view returns (DistributionWithoutClaimed memory);

    /** 
    * @dev Returns the id of the next distribution.
    */
    function _nextDistributionId() external view returns (uint256);
    
    /**
    * @dev Returns true if the index has been marked claimed.
    * @param index of the address and proof of the claimer
    * @param distributionId id of the distribution you want to check if index has been claimed
    */
    function isClaimed(uint256 index, uint256 distributionId) external view returns (bool);
    
    /**
    * @dev Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    * @param index index of the account that wants to claim
    * @param account address that wants to claim, and where the amount of tokens will be sent to
    * @param amount the amount that will be claimed
    * @param merkleProof proof that the account with index and amount is on the merkleTree, and can claim
    * @param distributionId id of the token distribution
    */
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof, uint256 distributionId) external;
    
    /**
    * @dev adds the pair of token and merkleRoot as new distributions
    * @param tokens that needs to be distributed
    * @param merkleRoots containing the information of index, address, value of the users that can claim
    * the token
    */
    function addDistributions(address[] memory tokens, bytes32[] memory merkleRoots) external;
    
    /**
    * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
    * direct transfers to the contract address.
    * @param erc20Token erc20 token to transfer
    * @param to recipient of the transfer
    * @param amount amount to send
    */
    function emergencyTokenTransfer(address erc20Token, address to, uint256 amount) external;

    /**
    * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
    * due selfdestructs or transfer ether to pre-computated contract address before deployment.
    * @param to recipient of the transfer
    * @param amount amount to send
    */
    function emergencyEtherTransfer(address to, uint256 amount) external;
}