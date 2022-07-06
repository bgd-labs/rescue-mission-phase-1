import { load } from 'cheerio';
import fetch from 'isomorphic-unfetch';

export const wait = (seconds: number) =>
  new Promise((resolve) => setTimeout(() => resolve(true), seconds * 1000));

export async function fetchLabel(
  address: string,
  labels: { [key: string]: string },
) {
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
  labels[address] = tags.join(',').trim();
  return labels[address];
}
