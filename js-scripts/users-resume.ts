import fs from "fs";

type UserInfo = {
    tokenAmount: string;
    tokenAmountInWei: string;
    proof: string[];
    index: number;
    distributionId: number;
}

type Claim = {
    index: number;
    amountInWei: string;
    amount: string;
    proof: string[];
}

type MerkleTree = {
    merkleRoot: string;
    tokenTotal: string;
    tokenTotalInWei: string;
    claims: Record<string, Claim>;
}

type UsersJson = Record<string, UserInfo[]>;

const merkleTree: Record<string, string> = {
    'AAVE': './js-scripts/maps/aaveRescueMerkleTree.json',
    'STK_AAVE': './js-scripts/maps/stkAaveRescueMerkleTree.json',
    'USDT': './js-scripts/maps/usdtRescueMerkleTree.json',
    'UNI': './js-scripts/maps/uniRescueMerkleTree.json',
}


const distributionIds: Record<string, number> = {
    'AAVE': 0,
    'STK_AAVE': 1,
    'USDT': 2,
    'UNI': 3
}

const getMerkleTreeJson = (path: string): MerkleTree => {
    try {
        const file = fs.readFileSync(path);
        // @ts-ignore
        return JSON.parse(file);
    } catch (error) {
        console.error(new Error(`unable to fetch ${path} with error: ${error}`));
        return {} as MerkleTree;
    }
};

const generateUsersJson = (): void => {
    const usersJson: UsersJson = {}

    for (const token of Object.keys(merkleTree)) {
        const merkleTreeJson = getMerkleTreeJson(merkleTree[token]);
        for (const claimer of Object.keys(merkleTreeJson.claims)) {
            if (!usersJson[claimer]) {
                usersJson[claimer] = [];
            }

            const claimerInfo = merkleTreeJson.claims[claimer];
            usersJson[claimer].push({
                tokenAmount: claimerInfo.amount,
                tokenAmountInWei: claimerInfo.amountInWei,
                proof: claimerInfo.proof,
                index: claimerInfo.index,
                distributionId: distributionIds[token]
            })
        }
    }

    fs.writeFileSync('./js-scripts/maps/usersMerkleTrees.json', JSON.stringify(usersJson));
}

generateUsersJson();