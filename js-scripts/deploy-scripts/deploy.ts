import 'dotenv/config';
import


import AutonomousProposal from '../../out/RescueAutonomousProposal.sol/RescueAutonomousProposal.json';
import ShortPayload from '../../out/ProposalPayloadShort.sol/ProposalPayloadShort.json';
import LongPayload from '../../out/ProposalPayloadLong.sol/ProposalPayloadLong.json';
import AaveMerkleDistributor from '../../out/AaveMerkleDistributor.sol/AaveMerkleDistributor.json';
import AaveTokenV2 from '../../out/AaveTokenV2.sol/AaveTokenV2.json';
import StkAaveTokenV2Rev4 from '../../out/StakedTokenV2Rev4.sol/StakedTokenV2Rev4.json';
import LendToAaveMigrator from '../../out/LendToAaveMigrator.sol/LendToAaveMigrator.json';
import { ethers, providers } from 'ethers';

const TENDERLY_FORK_URL = process.env.TENDERLY_FORK_URL;

if (!TENDERLY_FORK_URL)
  throw new Error('you have to set a GOV_CHAIN_TENDERLY_FORK_URL');

const provider = new providers.StaticJsonRpcProvider(TENDERLY_FORK_URL);

const AAVE_WHALE = '0x25F2226B597E8F9514B3F68F00f494cF4f286491';




// deploy AaveMerkleDistributor
const aaveMerkleDistributorFactory = new ethers.ContractFactory(
    AaveMerkleDistributor.abi,
    AaveMerkleDistributor.bytecode,
    provider.getSigner(AAVE_WHALE)
);
const aaveMerkleDistributorContract = await aaveMerkleDistributorFactory.deploy();
const changeDistributorOwner = await aaveMerkleDistributorContract.transferOwnership(Aave)






// deploy payload short


// deploy payload long

// deploy autonomous proposal

// move time forward

// create proposals

// move time and vote on proposals

// move time execute short

// move time execute long
