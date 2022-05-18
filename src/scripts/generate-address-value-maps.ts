import { BigNumber, Contract, Event, EventFilter, providers } from 'ethers';
import { IERC20__factory } from './typechain/IERC20__factory';
import fs from 'fs';
import { ChainId } from '@aave/contract-helpers';
import fetch from 'isomorphic-unfetch';
import { PromisePool } from '@supercharge/promise-pool';

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY ?? '';
const JSON_RPC_PROVIDER = {
  [ChainId.mainnet]: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
};

const TOKENS = {
  AAVE: '0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9',
  LEND: '0x80fB784B7eD66730e8b1DBd9820aFD29931aab03',
  STKAAVE: '0x4da27a545c0c5b758a6ba100e3a049001de870f5',
};

const migrator = '0x317625234562b1526ea2fac4030ea499c5291de4';

async function fetchTxns(
  symbol: keyof typeof TOKENS,
  to: string,
  network: keyof typeof JSON_RPC_PROVIDER,
  addressValueJson: Record<string, string>,
  validateEvent?: (events: Event[]) => Promise<Event[]>,
): Promise<Record<string, string>> {
  const token = TOKENS[symbol];
  const provider = new providers.StaticJsonRpcProvider(
    JSON_RPC_PROVIDER[network],
  );
  const contract = IERC20__factory.connect(token, provider);
  const event = contract.filters.Transfer(null, to);

  async function getPastLogs(
    fromBlock: number,
    toBlock: number,
  ): Promise<Event[]> {
    console.log(`fromBlock: ${fromBlock} toBlock: ${toBlock}`);
    if (fromBlock <= toBlock) {
      try {
        const events = await contract.queryFilter(event, fromBlock, toBlock);
        return events;
      } catch (error) {
        // alchemy specific solution, that optimizes, taking into account
        // alchemy error information
        // @ts-expect-error
        const { 0: newFromBlock, 1: newToBlock } = error.error.message
          .split('[')[1]
          .split(']')[0]
          .split(', ');

        console.log(
          contract.address,
          ' Error code: ',
          // @ts-expect-error
          error.error?.code,
          ' fromBloc: ',
          Number(newFromBlock),
          ' toBlock: ',
          Number(newToBlock),
        );

        const arr1 = await getPastLogs(
          Number(newFromBlock),
          Number(newToBlock),
        );
        const arr2 = await getPastLogs(Number(newToBlock), toBlock);
        return [...arr1, ...arr2];

        // solution that will work with generic rpcs
        // const midBlock = (fromBlock + toBlock) >> 1;
        // const arr1 = await getPastLogs(fromBlock, midBlock);
        // const arr2 = await getPastLogs(midBlock + 1, toBlock);
        // return [...arr1, ...arr2];
      }
    }
    return [];
  }

  const currentBlockNumber = await provider.getBlockNumber();
  let events = await getPastLogs(0, currentBlockNumber);
  if (validateEvent) events = await validateEvent(events);

  // Write events map of address value to json
  events.forEach((e: Event) => {
    if (e.args) {
      if (addressValueJson[e.args.from]) {
        const aggregatedValue = BigNumber.from(e.args.value.toString())
          .add(addressValueJson[e.args.from])
          .toString();
        addressValueJson[e.args.from] = aggregatedValue;
      } else {
        addressValueJson[e.args.from] = e.args.value.toString();
      }
    }
  });

  return addressValueJson;
}

async function validateMigrationEvents(events: Event[]): Promise<Event[]> {
  const { results, errors } = await PromisePool.for(events)
    .withConcurrency(50)
    .process(async (event) => {
      try {
        const receipt = await event.getTransactionReceipt();
        if (
          !receipt.logs.some((log) =>
            log.topics.includes(
              '0x5c5c7a8e729fa9bfdd1ecad2e8f7f3db1d29acf43c1e6036f34fd68621d15c81',
            ),
          )
        ) {
          return event;
        }
      } catch (e) {
        console.log('failed for', event);
      }
    });

  const invalidTxns: Event[] = results.filter(
    (r) => r !== undefined,
  ) as Event[];
  console.log(invalidTxns.length);
  return invalidTxns;
}

async function validateStkEvents(events: Event[]): Promise<Event[]> {
  console.log(events.length);
  const { results, errors } = await PromisePool.for(events)
    .withConcurrency(50)
    .process(async (event) => {
      try {
        const receipt = await event.getTransactionReceipt();
        if (
          !receipt.logs.some((log) =>
            log.topics.includes(
              '0x5dac0c1b1112564a045ba943c9d50270893e8e826c49be8e7073adc713ab7bd7',
            ),
          )
        ) {
          return event;
        }
      } catch (e) {
        console.log('failed for', event);
      }
    });

  const invalidTxns: Event[] = results.filter(
    (r) => r !== undefined,
  ) as Event[];
  console.log(invalidTxns.length);
  return invalidTxns;
}

async function main() {
  let addressValueJson: Record<string, string> = {};
  // dont use this as it was the initial minting from aave to the migrator, so no need to rescue anything from here
  // addressValueJson = await fetchTxns(
  //   'AAVE',
  //   migrator,
  //   ChainId.mainnet,
  //   addressValueJson,
  // );
  addressValueJson = await fetchTxns(
    'LEND',
    migrator,
    ChainId.mainnet,
    addressValueJson,
    validateMigrationEvents,
  );
  addressValueJson = await fetchTxns(
    'AAVE',
    TOKENS.AAVE,
    ChainId.mainnet,
    addressValueJson,
  );
  addressValueJson = await fetchTxns(
    'AAVE',
    TOKENS.LEND,
    ChainId.mainnet,
    addressValueJson,
  );
  addressValueJson = await fetchTxns(
    'LEND',
    TOKENS.AAVE,
    ChainId.mainnet,
    addressValueJson,
  );
  addressValueJson = await fetchTxns(
    'LEND',
    TOKENS.LEND,
    ChainId.mainnet,
    addressValueJson,
  );
  addressValueJson = await fetchTxns(
    'STKAAVE',
    TOKENS.STKAAVE,
    ChainId.mainnet,
    addressValueJson,
  );
  addressValueJson = await fetchTxns(
    'AAVE',
    TOKENS.STKAAVE,
    ChainId.mainnet,
    addressValueJson,
    validateStkEvents,
  );
  const path = `./maps/aaveRescueMap.json`;
  fs.writeFileSync(path, JSON.stringify(addressValueJson));
}

main().then(() => console.log('all-finished'));
