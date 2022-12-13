import aaveRescueMap from './maps/aaveRescueMap.json';
import stkAaveRescueMap from './maps/stkAaveRescueMap.json';
import uniRescueMap from './maps/uniRescueMap.json';
import usdtRescueMap from './maps/usdtRescueMap.json';
import { parseBalanceMap } from './parse-balance-map';
import fs from 'fs';

// phase 1
const aavePath = `./js-scripts/maps/aaveRescueMerkleTree.json`;
fs.writeFileSync(
  aavePath,
  JSON.stringify(parseBalanceMap(aaveRescueMap, 18, 'AAVE')),
);

const stkAavePath = `./js-scripts/maps/stkAaveRescueMerkleTree.json`;
fs.writeFileSync(
  stkAavePath,
  JSON.stringify(parseBalanceMap(stkAaveRescueMap, 18, 'stkAAVE')),
);

const uniPath = `./js-scripts/maps/uniRescueMerkleTree.json`;
fs.writeFileSync(
  uniPath,
  JSON.stringify(parseBalanceMap(uniRescueMap, 18, 'UNI')),
);

const usdtPath = `./js-scripts/maps/usdtRescueMerkleTree.json`;
fs.writeFileSync(
  usdtPath,
  JSON.stringify(parseBalanceMap(usdtRescueMap, 6, 'USDT')),
);
