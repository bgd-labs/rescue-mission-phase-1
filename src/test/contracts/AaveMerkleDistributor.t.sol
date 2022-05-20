// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import 'forge-std/Test.sol';

// import {AaveMerkleDistributor} from '../../contracts/AaveMerkleDistributor.sol';
// import {InitializableAdminUpgradeabilityProxy} from '../../src/contracts/dependencies/upgradeability/InitializableAdminUpgradeabilityProxy.sol';
// import {IERC20} from '../../src/contracts/dependencies/contracts/IERC20.sol';
// import {IAaveMerkleDistributor} from '../../src/contracts/interfaces/IAaveMerkleDistributor.sol';
// import {AaveMerkleDistributor} from '../../src/contracts/AaveMerkleDistributor.sol';

// contract AaveMerkleDistributorTest is Test {
//     using stdStorage for StdStorage;

//     IERC20 constant AAVE_TOKEN =
//         IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
//     bytes32 constant MERKLE_ROOT =
//         0x4c4d23a859f2a8f1e669f0f04e1af56fc87a27f86a85b66656b93993c985df21;
//     address AAVE_MERKLE_DISTRIBUTOR_IMPL;

//     // test claimer constants
//     address constant claimer = 0x00Af54516A94D1aC9eed55721215C8DE9970CdeE;
//     uint8 constant claimerIndex = 0;
//     uint256 constant claimerAmount = 3415740000000000000000;
//     bytes32[] claimerMerkleProof = [
//         bytes32(0x0436c315e2de71307442570329b4d84d6275cf715d4dbd93feda7af83bc88a95),
//         0x4c2cbf891dc53a2a70d8b2d1fff15503992f36e6816c7e7feefedda8f58141a5,
//         0xfd058858a5bed8c6839072b4a3524a1b077ee414ab2d2cf475f0522c2a8a1ade,
//         0xf2e5bc34b74f557165050040138c0312545692de30c5929fc0c9a01df3b71e69,
//         0x8f7063f3719ab23718b2f3457629da8b9934ce610704c075e969b1100449e3d5,
//         0xf03f8fa824ee510b5ef95ba24d8796e47a295c9b0b6ee4044c1a43f6ba23967a,
//         0xea4cb50e56dc0457ac9aa09b089b8ccc1d74f934442885784cffda11903349b0,
//         0xf492ddfa6d0e5a3133dfcd189b69db46f4fc13afadc6d102ac2035898c7214c1
//     ];

//     AaveMerkleDistributor aaveMerkleDistributor;

//     // This event is triggered whenever a call to #claim succeeds.
//     event Claimed(uint256 index, address indexed account, uint256 amount);

//     function setUp() public {
//         AAVE_MERKLE_DISTRIBUTOR_IMPL = address(new AaveMerkleDistributor());

//         // deploy proxy
//         InitializableAdminUpgradeabilityProxy distributorProxy = new InitializableAdminUpgradeabilityProxy();
//         // initialize
//         distributorProxy.initialize(
//             AAVE_MERKLE_DISTRIBUTOR_IMPL,
//             address(1),
//             abi.encodeWithSignature(
//                 'initialize(address,bytes32)',
//                 address(AAVE_TOKEN),
//                 MERKLE_ROOT
//             )
//         );

//         aaveMerkleDistributor = AaveMerkleDistributor(
//             address(distributorProxy)
//         );

//         assertEq(aaveMerkleDistributor.token(), address(AAVE_TOKEN));
//         assertEq(aaveMerkleDistributor.merkleRoot(), MERKLE_ROOT);

//         // add funds to distributor contract
//         deal(address(AAVE_TOKEN), address(distributorProxy), 10000000 ether);
//         assertEq(AAVE_TOKEN.balanceOf(address(aaveMerkleDistributor)), 10000000e18);
//     }

//     function testRevision() public {
//         assertEq(aaveMerkleDistributor.REVISION(), 0x1);
//     }

//     // TODO: this test makes it so we need to use contract instead of interface
//     // to have access to claimedBitMap. It also makes it so it needs to be public
//     // instead of private. Take a look at how we could improve on this  
//     function testIsClaimedTrue() public {
//         // prepared the claim index to overwrite
//         uint256 claimedWordIndex = 0 / 256;
//         uint256 claimedBitIndex = 0 % 256;

//         // set up storage so address x already claimed
//         stdstore
//             .target(address(aaveMerkleDistributor))
//             .sig(aaveMerkleDistributor.claimedBitMap.selector)
//             .with_key(claimedWordIndex)
//             .checked_write(1 << claimedBitIndex);
        
//         assertEq(aaveMerkleDistributor.isClaimed(0), true);
//     }

//     function testIsClaimedFalse() public {        
//         assertEq(aaveMerkleDistributor.isClaimed(0), false);
//     }

//     function testClaim() public {
//         // Check that topic 1, topic 2, and data are the same as the following emitted event.
//         vm.expectEmit(false, true, false, true);
//         // The event we expect
//         emit Claimed(claimerIndex, claimer, claimerAmount);

//         // The event we get
//         aaveMerkleDistributor.claim(claimerIndex, claimer, claimerAmount, claimerMerkleProof);
//     }

//     function testWhenAlreadyClaimed() public {
//         // prepared the claim index to overwrite
//         uint256 claimedWordIndex = 0 / 256;
//         uint256 claimedBitIndex = 0 % 256;

//         // set up storage so address x already claimed
//         stdstore
//             .target(address(aaveMerkleDistributor))
//             .sig(aaveMerkleDistributor.claimedBitMap.selector)
//             .with_key(claimedWordIndex)
//             .checked_write(1 << claimedBitIndex);
        
//         // vm.expectRevert(aaveMerkleDistributor.DropAlreadyClaimed.selector);
//         vm.expectRevert(bytes('MerkleDistributor: Drop already claimed.'));

//         aaveMerkleDistributor.claim(claimerIndex, claimer, claimerAmount, claimerMerkleProof);
//     }

//     function testWhenInvalidProof() public {
//         vm.expectRevert(bytes('MerkleDistributor: Invalid proof.'));

//         aaveMerkleDistributor.claim(claimerIndex, address(2), claimerAmount, claimerMerkleProof);
//     }

//     function testWhenNotEnoughFunds() public {

//         // lower the funds of the distributor
//         stdstore
//             .target(address(AAVE_TOKEN))
//             .sig(AAVE_TOKEN.balanceOf.selector)
//             .with_key(address(aaveMerkleDistributor))
//             .checked_write(1);
        

//         // TODO: why is it not returning the error of the distributor contract, but 
//         // instead returning the one from inside transfer
//         // vm.expectRevert(bytes('MerkleDistributor: Transfer failed.'));
//         vm.expectRevert(bytes('SafeMath: subtraction overflow'));

//         aaveMerkleDistributor.claim(claimerIndex, claimer, claimerAmount, claimerMerkleProof);
//     }

//     // TODO: are we missing test cases??
// }
