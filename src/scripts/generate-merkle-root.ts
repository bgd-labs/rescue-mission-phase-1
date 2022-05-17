import aaveLend from '../../maps/AAVE-lend.json';
import aaveMigrator from '../../maps/AAVE-migrator.json';
import aaveSelf from '../../maps/AAVE-self.json';
import aaveStkaave from '../../maps/AAVE-stkAAVE.json';
import lendAave from '../../maps/LEND-aave.json';
import lendMigrator from '../../maps/LEND-migrator.json';
import lendSelf from '../../maps/LEND-self.json';
import stkaaveSelf from '../../maps/STKAAVE-self.json';
import { parseBalanceMap } from './parse-balance-map';

console.log('aaveLend ::: ', JSON.stringify(parseBalanceMap(aaveLend)));
console.log('aaveMigrator ::: ', JSON.stringify(parseBalanceMap(aaveMigrator)));
console.log('aaveSelf ::: ', JSON.stringify(parseBalanceMap(aaveSelf)));
console.log('aaveStkaave ::: ', JSON.stringify(parseBalanceMap(aaveStkaave)));
console.log('lendAave ::: ', JSON.stringify(parseBalanceMap(lendAave)));
console.log('lendMigrator ::: ', JSON.stringify(parseBalanceMap(lendMigrator)));
console.log('lendSelf ::: ', JSON.stringify(parseBalanceMap(lendSelf)));
console.log('stkaaveSelf ::: ', JSON.stringify(parseBalanceMap(stkaaveSelf)));
