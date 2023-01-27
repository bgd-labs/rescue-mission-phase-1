import 'dotenv/config';
import { ethers, providers } from 'ethers';

import * as AaveGovernanceV2 from '../../lib/aave-address-book/src/ts/AaveGovernanceV2';
import AutonomousProposal from '../../out/RescueAutonomousProposal.sol/RescueAutonomousProposal.json';
import ShortPayload from '../../out/ProposalPayloadShort.sol/ProposalPayloadShort.json';
import LongPayload from '../../out/ProposalPayloadLong.sol/ProposalPayloadLong.json';
import AaveMerkleDistributor from '../../out/AaveMerkleDistributor.sol/AaveMerkleDistributor.json';
import AaveTokenV2 from '../../out/AaveTokenV2.sol/AaveTokenV2.json';
import StkAaveTokenV2Rev4 from '../../out/StakedTokenV2Rev4.sol/StakedTokenV2Rev4.json';
import LendToAaveMigrator from '../../out/LendToAaveMigrator.sol/LendToAaveMigrator.json';
import IGovernancePowerDelegationToken from '../../out/IGovernancePowerDelegationToken.sol/IGovernancePowerDelegationToken.json';
import GovernanceV2 from '../../out/AaveGovernanceV2.sol/AaveGovernanceV2.json';

const TENDERLY_FORK_URL = process.env.TENDERLY_FORK_URL;

if (!TENDERLY_FORK_URL)
  throw new Error('you have to set a GOV_CHAIN_TENDERLY_FORK_URL');

const provider = new providers.StaticJsonRpcProvider(TENDERLY_FORK_URL);

const AAVE_WHALE = '0x25F2226B597E8F9514B3F68F00f494cF4f286491';
const AAVE_WHALE_2 = '0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9';
const AAVE_TOKEN = '0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9';
const LEND_TOKEN = '0x80fB784B7eD66730e8b1DBd9820aFD29931aab03';

// lend to aave migration configurations
const LEND_AAVE_RATIO = 100;

// stk aave configurations
const STAKED_TOKEN = AAVE_TOKEN;
const REWARD_TOKEN = AAVE_TOKEN;
const COOLDOWN_SECONDS = 864000;
const UNSTAKE_WINDOW = 172800;
const REWARDS_VAULT = '0x25F2226B597E8F9514B3F68F00f494cF4f286491'; // ecosystem reserve
const EMISSION_MANAGER = AaveGovernanceV2.SHORT_EXECUTOR;
const DISTRIBUTION_DURATION = 3155692600;
const STK_NAME = 'Staked Aave';
const STK_SYMBOL = 'stkAAVE';
const STK_DECIMALS = 18;

// autonomous proposal configurations
const SHORT_IPFS =
  '0x22f22ad910127d3ca76dc642f94db34397f94ca969485a216b9d82387808cdfa';
const LONG_IPFS =
  '0xd0b98a12db1859322818b5943127735ca545d437d09dc0aa7dbcf9e66ac01569';

const giveEthToWhales = async () => {
  const WALLETS = [AAVE_WHALE, AAVE_WHALE_2];

  await provider.send('tenderly_addBalance', [
    WALLETS,
    //amount in wei will be added for all wallets
    ethers.utils.hexValue(
      ethers.utils.parseUnits('1000', 'ether').toHexString(),
    ),
  ]);
};

const deploy = async () => {
  await giveEthToWhales();
  //--------------------------------------------------------------------------------------------------------------------
  //                                            DEPLOY DEPENDENCY CONTRACTS
  //--------------------------------------------------------------------------------------------------------------------

  // deploy AaveMerkleDistributor
  const aaveMerkleDistributorFactory = new ethers.ContractFactory(
    AaveMerkleDistributor.abi,
    AaveMerkleDistributor.bytecode,
    provider.getSigner(AAVE_WHALE),
  );
  const aaveMerkleDistributorContract =
    await aaveMerkleDistributorFactory.deploy();
  const changeDistributorOwnerTx =
    await aaveMerkleDistributorContract.transferOwnership(
      AaveGovernanceV2.SHORT_EXECUTOR,
    );
  await changeDistributorOwnerTx.wait();
  console.log(
    `[AaveMerkleDistributor]: ${aaveMerkleDistributorContract.address}`,
  );

  // deploy AaveTokenImpl
  const aaveTokenV2Factory = new ethers.ContractFactory(
    AaveTokenV2.abi,
    AaveTokenV2.bytecode,
    provider.getSigner(AAVE_WHALE),
  );
  const aaveTokenV2Contract = await aaveTokenV2Factory.deploy();
  console.log(`[AaveTokenV2Impl]: ${aaveTokenV2Contract.address}`);

  // deploy StkAaveTokenV2Rev4
  const stkAaveTokenV2Rev4Factory = new ethers.ContractFactory(
    StkAaveTokenV2Rev4.abi,
    StkAaveTokenV2Rev4.bytecode,
    provider.getSigner(AAVE_WHALE),
  );
  const stkAaveTokenV2Rev4Contract = await stkAaveTokenV2Rev4Factory.deploy(
    STAKED_TOKEN,
    REWARD_TOKEN,
    COOLDOWN_SECONDS,
    UNSTAKE_WINDOW,
    REWARDS_VAULT,
    EMISSION_MANAGER,
    DISTRIBUTION_DURATION,
    STK_NAME,
    STK_SYMBOL,
    STK_DECIMALS,
  );
  console.log(
    `[StkAaveTokenV2Rev4Impl]: ${stkAaveTokenV2Rev4Contract.address}`,
  );

  // deploy LendToAaveMigrator
  const lendToAaveMigratorFactory = new ethers.ContractFactory(
    LendToAaveMigrator.abi,
    LendToAaveMigrator.bytecode,
    provider.getSigner(AAVE_WHALE),
  );
  const lendToAaveMigratorContract = await lendToAaveMigratorFactory.deploy(
    AAVE_TOKEN,
    LEND_TOKEN,
    LEND_AAVE_RATIO,
  );
  console.log(
    `[LendToAaveMigratorImpl]: ${lendToAaveMigratorContract.address}`,
  );

  //--------------------------------------------------------------------------------------------------------------------
  //                                            DEPLOY PAYLOADS
  //--------------------------------------------------------------------------------------------------------------------

  // deploy payload short
  const shortPayloadFactory = new ethers.ContractFactory(
    ShortPayload.abi,
    ShortPayload.bytecode,
    provider.getSigner(AAVE_WHALE),
  );

  const shortPayloadContract = await shortPayloadFactory.deploy(
    aaveMerkleDistributorContract.address,
    lendToAaveMigratorContract.address,
  );
  console.log(`[ShortPayload]: ${shortPayloadContract.address}`);

  // deploy payload long
  const longPayloadFactory = new ethers.ContractFactory(
    LongPayload.abi,
    LongPayload.bytecode,
    provider.getSigner(AAVE_WHALE),
  );
  const longPayloadContract = await longPayloadFactory.deploy(
    aaveMerkleDistributorContract.address,
    aaveTokenV2Contract.address,
    stkAaveTokenV2Rev4Contract.address,
  );
  console.log(`[LongPayload]: ${longPayloadContract.address}`);

  //--------------------------------------------------------------------------------------------------------------------
  //                                            DEPLOY PROPOSAL
  //--------------------------------------------------------------------------------------------------------------------

  // deploy autonomous proposal
  const creationTimestamp = Math.floor(Date.now() / 1000) + 60 * 60 * 24; // now + 1 day
  const autonomousProposalFactory = new ethers.ContractFactory(
    AutonomousProposal.abi,
    AutonomousProposal.bytecode,
    provider.getSigner(AAVE_WHALE),
  );
  const autonomousProposalContract = await autonomousProposalFactory.deploy(
    shortPayloadContract.address,
    longPayloadContract.address,
    SHORT_IPFS,
    LONG_IPFS,
    creationTimestamp,
  );
  console.log(`[AutonomousProposal]: ${autonomousProposalContract.address}`);

  //--------------------------------------------------------------------------------------------------------------------
  //                                            PASS PROPOSAL
  //--------------------------------------------------------------------------------------------------------------------

  // delegate to autonomous
  const delegationContract = new ethers.Contract(
    AAVE_TOKEN,
    IGovernancePowerDelegationToken.abi,
    provider.getSigner(AAVE_WHALE),
  );
  const powerDelegationTx = await delegationContract.delegateByType(
    autonomousProposalContract.address,
    1, // power
  );
  await powerDelegationTx.wait();

  // forward time to create window
  let currentBlockNumber = provider.getBlockNumber();
  let currentBlock = await provider.getBlock(currentBlockNumber);
  await provider.send('evm_increaseTime', [
    ethers.BigNumber.from(creationTimestamp)
      .sub(currentBlock.timestamp)
      .add(1)
      .toNumber(),
  ]);

  // create proposals
  const createProposalsTx = await autonomousProposalContract.create();
  await createProposalsTx.wait();
  const shortProposalId =
    await autonomousProposalContract.shortExecutorProposalId();
  const longProposalId =
    await autonomousProposalContract.longExecutorProposalId();
  console.log(`
    ShortProposalId: ${shortProposalId}
    LongProposalId: ${longProposalId}
  `);

  // forward time for voting
  currentBlockNumber = provider.getBlockNumber();
  currentBlock = await provider.getBlock(currentBlockNumber);
  await provider.send('evm_increaseTime', [
    ethers.BigNumber.from(creationTimestamp + 60 * 60 * 24 * 2) // creation time + 2 days
      .sub(currentBlock.timestamp)
      .add(1)
      .toNumber(),
  ]);

  // vote on proposals
  const govContractAaveWhale = new ethers.Contract(
    AaveGovernanceV2.GOV,
    GovernanceV2.abi,
    provider.getSigner(AAVE_WHALE),
  );
  const voteShortTx = await govContractAaveWhale.submitVote(
    shortProposalId,
    true,
  );
  await voteShortTx.wait();
  const voteLongTx = await govContractAaveWhale.submitVote(
    longProposalId,
    true,
  );
  await voteLongTx.wait();
  const govContractAaveWhale2 = new ethers.Contract(
    AaveGovernanceV2.GOV,
    GovernanceV2.abi,
    provider.getSigner(AAVE_WHALE_2),
  );
  const voteLongTx2 = await govContractAaveWhale2.submitVote(
    longProposalId,
    true,
  );
  await voteLongTx2.wait();

  // forward time to end of vote for short proposal

  // queue short proposal
  const queueShortTx = await govContractAaveWhale.queue(shortProposalId);
  await queueShortTx.wait();

  // forward time for short proposal execution
  currentBlockNumber = provider.getBlockNumber();
  currentBlock = await provider.getBlock(currentBlockNumber);
  await provider.send('evm_increaseTime', [
    ethers.BigNumber.from(creationTimestamp + 60 * 60 * 24 * 2) // creation time + 2 days
      .sub(currentBlock.timestamp)
      .add(1)
      .toNumber(),
  ]);

  // execute short proposal
  const executeShortTx = await govContractAaveWhale.execute(shortProposalId);
  await executeShortTx.wait();

  // forward time to end of vote for short proposal

  // queue long proposal
  const queueLongTx = await govContractAaveWhale.queue(longProposalId);
  await queueLongTx.wait();

  // forward time for long proposal execution

  // execute long proposal
  const executeLongTx = await govContractAaveWhale.execute(longProposalId);
  await executeLongTx.wait();
};

deploy().then().catch();
