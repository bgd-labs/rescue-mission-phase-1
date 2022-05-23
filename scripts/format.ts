import aaveRescueMap from './maps/aaveRescueMap.json';
import uniRescueMap from './maps/uniRescueMap.json';
import usdtRescueMap from './maps/usdtRescueMap.json';
import { normalize } from '@aave/math-utils';
import fs from 'fs';

const format = (
  jsonObj: Record<string, string>,
  name: string,
  decimals: number,
) => {
  const newObj: Record<string, string> = {};
  Object.keys(jsonObj).forEach((key) => {
    newObj[key] = `${normalize(jsonObj[key], decimals)} ${name}`;
  });

  const path = `./scripts/maps/${name}RescueMapFormatted.json`;
  fs.writeFileSync(path, JSON.stringify(newObj));
};

format(aaveRescueMap, 'AAVE', 18);
format(uniRescueMap, 'UNI', 18);
format(usdtRescueMap, 'USDT', 6);
