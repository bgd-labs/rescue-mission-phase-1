import { BigNumber, ethers, providers, utils } from 'ethers';

import GovernanceV2 from '../../out/AaveGovernanceV2.sol/AaveGovernanceV2.json';
import * as AaveGovernanceV2 from '../../lib/aave-address-book/src/ts/AaveGovernanceV2';

interface DefaultInterface {
  provider: providers.StaticJsonRpcProvider;
}

interface PassAndExecuteProposal extends DefaultInterface {
  proposalId: number;
}

const AAVE_WHALE = '0x25F2226B597E8F9514B3F68F00f494cF4f286491';

export async function passAndExecuteProposal({
  proposalId,
  provider,
}: PassAndExecuteProposal) {
  const governance = new ethers.Contract(
    AaveGovernanceV2.GOV,
    GovernanceV2.abi,
    provider.getSigner(AAVE_WHALE),
  );
  const currentProposalState = await governance.getProposalState(proposalId);
  // no need to queue when it's already queued
  if (currentProposalState !== 5) {
    // alter forVotes storage so the proposal passes
    await provider.send('tenderly_setStorageAt', [
      AaveGovernanceV2.GOV,
      BigNumber.from(
        utils.keccak256(
          utils.defaultAbiCoder.encode(
            ['uint256', 'uint256'],
            [proposalId, '0x4'],
          ),
        ),
      )
        .add(11)
        .toHexString(),
      utils.hexZeroPad(utils.parseEther('5000000').toHexString(), 32),
    ]);
    // queue proposal
    const activeProposal = await governance.getProposalById(proposalId);
    const delay = await governance.getVotingDelay();
    await provider.send('evm_increaseBlocks', [
      BigNumber.from(activeProposal.endBlock)
        .sub(BigNumber.from(activeProposal.startBlock))
        .add(delay)
        .add(1)
        .toHexString(),
    ]);

    await governance.queue(proposalId);
  }

  // execute proposal
  const queuedProposal = await governance.getProposalById(proposalId);
  const timestamp = (await (provider as any).getBlock()).timestamp;
  await provider.send('evm_increaseTime', [
    BigNumber.from(queuedProposal.executionTime)
      .sub(timestamp)
      .add(1)
      .toNumber(),
  ]);

  await governance.execute(proposalId);
  console.log('Proposal executed');
}
