import * as R from "ramda";

import { BigNumber } from "ethers";
import { ethers } from "hardhat";

const main = async (
  composition: { token: string; amount: BigNumber }[],
  tokenExchanger: string,
  indexToken: string,
  reserve: string,
  feeController: string
) => {
  const indexFactory = await ethers.getContractFactory("Index");
  const index = await indexFactory.deploy(
    R.pluck("token", composition),
    R.pluck("amount", composition),
    tokenExchanger,
    indexToken,
    reserve,
    "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
    feeController,
    10
  );
  console.log("deployed index", index.address);
  return index.address;
};

export default main;
