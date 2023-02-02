import { BigNumber, utils } from 'ethers';
import BalanceTree from './merkle-trees/balance-tree';
import { normalize } from '@aave/math-utils';

const { isAddress, getAddress } = utils;

// This is the blob that gets distributed and pinned to IPFS.
// It is completely sufficient for recreating the entire merkle tree.
// Anyone can verify that all air drops are included in the tree,
// and the tree has no additional distributions.
interface MerkleDistributorInfo {
  merkleRoot: string;
  tokenTotal: string;
  tokenTotalInWei: string;
  claims: {
    [account: string]: {
      index: number;
      amount: string;
      amountInWei: string;
      proof: string[];
      flags?: {
        [flag: string]: boolean;
      };
    };
  };
}

type OldFormat = {
  [account: string]: { amount: string; label?: string; txns: string[] };
};
type NewFormat = { address: string; earnings: string; reasons: string };

export function parseBalanceMap(
  balances: OldFormat | NewFormat[],
  decimals: number,
  name: string,
): MerkleDistributorInfo {
  // if balances are in an old format, process them
  const balancesInNewFormat: NewFormat[] = Array.isArray(balances)
    ? balances
    : Object.keys(balances).map(
        (account): NewFormat => ({
          address: account,
          earnings: balances[account].amount.toString(), //`0x${balances[account].toString(16)}`,
          reasons: '',
        }),
      );

  const dataByAddress = balancesInNewFormat.reduce<{
    [address: string]: {
      amount: BigNumber;
      flags?: { [flag: string]: boolean };
    };
  }>((memo, { address: account, earnings, reasons }) => {
    if (!isAddress(account)) {
      throw new Error(`Found invalid address: ${account}`);
    }
    const parsed = getAddress(account);
    if (memo[parsed]) throw new Error(`Duplicate address: ${parsed}`);
    const parsedNum = BigNumber.from(earnings);
    if (parsedNum.lte(0))
      throw new Error(`Invalid amount for account: ${account}`);

    const flags = {
      isSOCKS: reasons.includes('socks'),
      isLP: reasons.includes('lp'),
      isUser: reasons.includes('user'),
    };

    memo[parsed] = { amount: parsedNum, ...(reasons === '' ? {} : { flags }) };
    return memo;
  }, {});

  const sortedAddresses = Object.keys(dataByAddress).sort();

  // construct a tree
  const tree = new BalanceTree(
    sortedAddresses.map((address) => ({
      account: address,
      amount: dataByAddress[address].amount,
    })),
  );

  // generate claims
  const claims = sortedAddresses.reduce<{
    [address: string]: {
      amount: string;
      amountInWei: string;
      index: number;
      proof: string[];
      flags?: { [flag: string]: boolean };
    };
  }>((memo, address, index) => {
    const { amount, flags } = dataByAddress[address];
    memo[address] = {
      index,
      amountInWei: amount.toString(),
      amount: `${normalize(amount.toString(), decimals)} ${name}`,
      proof: tree.getProof(index, address, amount),
      ...(flags ? { flags } : {}),
    };
    return memo;
  }, {});

  const tokenTotal: BigNumber = sortedAddresses.reduce<BigNumber>(
    (memo, key) => memo.add(dataByAddress[key].amount),
    BigNumber.from(0),
  );

  return {
    merkleRoot: tree.getHexRoot(),
    tokenTotal: `${normalize(tokenTotal.toString(), decimals)} ${name}`,
    tokenTotalInWei: tokenTotal.toString(),
    claims,
  };
}
