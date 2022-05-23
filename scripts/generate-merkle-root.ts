import aaveRescueMap from './maps/aaveRescueMap.json';
import uniRescueMap from './maps/uniRescueMap.json';
import usdtRescueMap from './maps/usdtRescueMap.json';
import { parseBalanceMap } from './parse-balance-map';
import fs from 'fs';

// phase 1
const aavePath = `./scripts/maps/aaveRescueMerkleTree.json`;
fs.writeFileSync(
  aavePath,
  JSON.stringify(parseBalanceMap(aaveRescueMap, 18, 'AAVE')),
);

const uniPath = `./scripts/maps/uniRescueMerkleTree.json`;
fs.writeFileSync(
  uniPath,
  JSON.stringify(parseBalanceMap(uniRescueMap, 18, 'UNI')),
);

const usdtPath = `./scripts/maps/usdtRescueMerkleTree.json`;
fs.writeFileSync(
  usdtPath,
  JSON.stringify(parseBalanceMap(usdtRescueMap, 6, 'USDT')),
);
