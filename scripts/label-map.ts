import fs from 'fs';
import { load } from 'cheerio';
import fetch from 'isomorphic-unfetch';

const wait = (seconds: number) =>
  new Promise((resolve) => setTimeout(() => resolve(true), seconds * 1000));

async function fetchLabel(address: string, labels: { [key: string]: string }) {
  if (labels[address] !== undefined) return labels[address];
  const response = await fetch(`https://etherscan.io/address/${address}`);
  await wait(0.3);
  const body = await response.text();
  const $ = load(body);
  const tags: string[] = [];
  $(
    'a[href*="/accounts/label"].mb-1.mb-sm-0.u-label.u-label--xs.u-label--info',
  ).each((i, node) => {
    const text = $(node).text();
    tags.push(text);
  });
  labels[address] = tags.join(',');
  return labels[address];
}

async function enhanceMapWithLabel(fileName: string) {
  const labels = require('./labels/labels.json');
  const map = require(`./maps/${fileName}`);
  const newMap: { [key: string]: { amount: string; label: string } } = {};
  for (let key of Object.keys(map)) {
    try {
      const label = await fetchLabel(key, labels);
      if (label) {
        newMap[key] = { amount: map[key], label: label };
      }
    } catch (e) {
      console.log(`error fetching label for ${key}`);
    }
  }
  fs.writeFileSync('./scripts/labels/labels.json', JSON.stringify(labels));
  fs.writeFileSync(
    `./scripts/labels/labeled_${fileName}`,
    JSON.stringify(newMap),
  );
}

async function main() {
  // running after each other so they can work with same label map
  await enhanceMapWithLabel('aaveRescueMap.json');
  await enhanceMapWithLabel('stkAaveRescueMap.json');
  await enhanceMapWithLabel('uniRescueMap.json');
  await enhanceMapWithLabel('usdtRescueMap.json');
}

main();
