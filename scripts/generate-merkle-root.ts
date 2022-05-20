import aaveRescueMap from './maps/aaveRescueMap.json';
import { parseBalanceMap } from './parse-balance-map';
import fs from 'fs';

const path = `./maps/aaveRescueMerkleTree.json`;
fs.writeFileSync(path, JSON.stringify(parseBalanceMap(aaveRescueMap)));

// console.log('aaveLend ::: ', JSON.stringify(parseBalanceMap(aaveRescueMap)));
