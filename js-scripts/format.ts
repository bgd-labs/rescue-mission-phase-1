import aaveRescueMap from './maps/aaveRescueMap.json';
import uniRescueMap from './maps/uniRescueMap.json';
import usdtRescueMap from './maps/usdtRescueMap.json';
import stkAaveRescueMap from './maps/stkAaveRescueMap.json';
import { normalize } from '@aave/math-utils';
import fs from 'fs';

const format = (
  jsonObj: Record<string, { amount: string; label?: string }>,
  name: string,
  decimals: number,
) => {
  const newObj: Record<string, string> = {};
  Object.keys(jsonObj).forEach((key) => {
    newObj[key] = `${normalize(jsonObj[key].amount, decimals)} ${name}${
      jsonObj[key].label ? ` ${jsonObj[key].label}` : ''
    }`;
  });

  const path = `./js-scripts/maps/${name}RescueMapFormatted.json`;
  fs.writeFileSync(path, JSON.stringify(newObj, null, 2));
};

format(aaveRescueMap, 'AAVE', 18);
format(stkAaveRescueMap, 'stkAAVE', 18);
format(uniRescueMap, 'UNI', 18);
format(usdtRescueMap, 'USDT', 6);
