// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Allows anyone to claim a token if they exist in a merkle root.
interface IAaveMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token(uint256 distributionId) external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot(uint256 distributionId) external view returns (bytes32);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index, uint256 distributionId) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof, uint256 distributionId) external;
    // Add distributions. Only callable by owner
    function addDistributions(address[] memory tokens, bytes32[], memory merkleRoots) external;
    // Emergency transfers of ERC20. Only callable by owner
    function emergencyTokenTransfer(address erc20TOken, address to, uint256 amount) external;
    // Emergency transfers of ETH. Only callable by owner
    emergencyEtherTransfer(address to, uint256 amount) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address indexed account, uint256 amount, uint256 indexed distributionId);
    // this event is triggered when adding a new distribution
    event Distribution(address indexed token, bytes32 indexed merkleRoot, uint256 indexed distributionId);
}