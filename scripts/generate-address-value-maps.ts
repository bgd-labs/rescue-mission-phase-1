import { BigNumber, Event, providers } from 'ethers';
import { IERC20__factory } from './typechain/IERC20__factory';
import fs from 'fs';
import { ChainId } from '@aave/contract-helpers';
import { PromisePool } from '@supercharge/promise-pool';
import { fetchLabel } from './label-map';

const amountsFilePath = `./scripts/maps/amountsByContract.txt`;

const JSON_RPC_PROVIDER = {
  [ChainId.mainnet]: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
};

const TOKENS = {
  AAVE: '0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9',
  LEND: '0x80fB784B7eD66730e8b1DBd9820aFD29931aab03',
  STKAAVE: '0x4da27a545c0c5b758a6ba100e3a049001de870f5',
  UNI: '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984',
  USDT: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
};

const migrator = '0x317625234562b1526ea2fac4030ea499c5291de4';

async function fetchTxns(
  symbol: keyof typeof TOKENS,
  to: string,
  network: keyof typeof JSON_RPC_PROVIDER,
  name: string,
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
        // @ts-expect-error
        if (error.error?.message?.indexOf('[') > -1) {
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
          const arr2 = await getPastLogs(Number(newToBlock) + 1, toBlock);
          return [...arr1, ...arr2];
        } else {
          // solution that will work with generic rpcs or
          // if alchemy fails with different error
          const midBlock = (fromBlock + toBlock) >> 1;
          const arr1 = await getPastLogs(fromBlock, midBlock);
          const arr2 = await getPastLogs(midBlock + 1, toBlock);
          return [...arr1, ...arr2];
        }
      }
    }
    return [];
  }

  const currentBlockNumber = await provider.getBlockNumber();
  let events = await getPastLogs(0, currentBlockNumber);
  if (validateEvent) events = await validateEvent(events);

  // Write events map of address value to json
  const addressValueMap: Record<string, string> = {};
  let totalValue = BigNumber.from(0);
  events.forEach((e: Event) => {
    if (e.args) {
      let value = BigNumber.from(e.args.value.toString());
      if (value.gt(0)) {
        totalValue = totalValue.add(value);
        // if we are looking at LEND token rescue
        // we need to divide by 100 as users will get the rescue amount
        // in AAVE tokens
        if (symbol === 'LEND') {
          value = BigNumber.from(e.args.value.toString()).div(100);
        }
        if (addressValueMap[e.args.from]) {
          const aggregatedValue = value
            .add(addressValueMap[e.args.from])
            .toString();
          addressValueMap[e.args.from] = aggregatedValue;
        } else {
          addressValueMap[e.args.from] = value.toString();
        }
      }
    }
  });

  // write total amount on txt
  fs.appendFileSync(
    amountsFilePath,
    `total amount for ${name} in wei: ${totalValue} ${symbol}\r\n`,
  );

  return addressValueMap;
}

async function validateMigrationEvents(events: Event[]): Promise<Event[]> {
  console.log('validate migration events: ', events.length);
  const { results, errors } = await PromisePool.for(events)
    .withConcurrency(10)
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

  const validTxns: Event[] = results.filter((r) => r !== undefined) as Event[];
  console.log('valid migration tx: ', validTxns.length);
  return validTxns;
}

async function validateStkAaveEvents(events: Event[]): Promise<Event[]> {
  console.log('validate stk events: ', events.length);
  const { results, errors } = await PromisePool.for(events)
    .withConcurrency(10)
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

  const validTxns: Event[] = results.filter((r) => r !== undefined) as Event[];
  console.log('valid stk tx: ', validTxns.length);
  return validTxns;
}

async function generateAndSaveMap(
  mappedContracts: Record<string, string>[],
  name: string,
): Promise<void> {
  const aggregatedMapping: Record<
    string,
    { amount: string; txns: number; label?: string }
  > = {};
  const labels = require('./labels/labels.json');
  for (let mappedContract of mappedContracts) {
    for (let address of Object.keys(mappedContract)) {
      if (aggregatedMapping[address]) {
        const aggregatedValue = BigNumber.from(
          mappedContract[address].toString(),
        )
          .add(aggregatedMapping[address].amount)
          .toString();
        aggregatedMapping[address].amount = aggregatedValue;
        aggregatedMapping[address].txns += 1;
      } else {
        aggregatedMapping[address] = {} as any;
        aggregatedMapping[address].amount = mappedContract[address].toString();
        aggregatedMapping[address].txns = 1;
        const label = await fetchLabel(address, labels);
        if (label) {
          aggregatedMapping[address].label = label;
        }
      }
    }
  }

  const path = `./scripts/maps/${name}RescueMap.json`;
  fs.writeFileSync(path, JSON.stringify(aggregatedMapping, null, 2));
}

async function generateAaveMap() {
  // dont use this as it was the initial minting from aave to the migrator, so no need to rescue anything from here
  // await fetchTxns('AAVE', migrator, ChainId.mainnet);
  const mappedContracts: Record<string, string>[] = await Promise.all([
    fetchTxns(
      'LEND',
      migrator,
      ChainId.mainnet,
      'LEND-MIGRATOR',
      validateMigrationEvents,
    ),
    fetchTxns('AAVE', TOKENS.AAVE, ChainId.mainnet, 'AAVE-AAVE'),
    // can't recuperate aave sent to lend as lend is not upgreadable
    // fetchTxns('AAVE', TOKENS.LEND, ChainId.mainnet, 'AAVE-LEND'),
    fetchTxns('LEND', TOKENS.AAVE, ChainId.mainnet, 'LEND-AAVE'),
    fetchTxns('LEND', TOKENS.LEND, ChainId.mainnet, 'LEND-LEND'),
    fetchTxns(
      'AAVE',
      TOKENS.STKAAVE,
      ChainId.mainnet,
      'AAVE-STKAAVE',
      validateStkAaveEvents,
    ),
  ]);

  return generateAndSaveMap(mappedContracts, 'aave');
}

async function generateStkAaveMap() {
  const mappedContracts: Record<string, string>[] = await Promise.all([
    fetchTxns('STKAAVE', TOKENS.STKAAVE, ChainId.mainnet, 'STKAAVE-STKAAVE'),
  ]);

  return generateAndSaveMap(mappedContracts, 'stkAave');
}

async function generateUniMap() {
  // dont use this as it was the initial minting from aave to the migrator, so no need to rescue anything from here
  // await fetchTxns('AAVE', migrator, ChainId.mainnet);
  const mapedContracts: Record<string, string>[] = await Promise.all([
    fetchTxns('UNI', TOKENS.AAVE, ChainId.mainnet, 'UNI-AAVE'),
  ]);

  return generateAndSaveMap(mapedContracts, 'uni');
}

async function generateUsdtMap() {
  // dont use this as it was the initial minting from aave to the migrator, so no need to rescue anything from here
  // await fetchTxns('AAVE', migrator, ChainId.mainnet);
  const mapedContracts: Record<string, string>[] = await Promise.all([
    fetchTxns('USDT', TOKENS.AAVE, ChainId.mainnet, 'USDT-AAVE'),
  ]);

  return generateAndSaveMap(mapedContracts, 'usdt');
}

// Phase 1
async function phase1() {
  fs.writeFileSync(amountsFilePath, '');
  await generateAaveMap();
  await generateStkAaveMap();
  await generateUniMap();
  await generateUsdtMap();
}

phase1().then(() => console.log('all finished'));
