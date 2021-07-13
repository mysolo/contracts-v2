import * as R from "ramda";

import { BigNumber, Contract } from "ethers";
import { expandTo18Decimals, getAddresses } from "./utils";

import { Interface } from "ethers/lib/utils";
import { computeTargetWeights } from "./compute-token-amounts";
import { ethers } from "hardhat";
import { getContract } from "./contracts";
import routerArtifact from "./IUniswapV2Router02.json";

const main = async (
  composition: { token: string; weight: number }[],
  tokenExchanger: string,
  indexToken: string,
  reserve: string,
  feeController: string
) => {
  const [signer] = await ethers.getSigners();
  const addresses = getAddresses();
  const indexFactory = await ethers.getContractFactory("Index");
  console.log("target composition", composition);
  const tokens = R.pluck("token", composition);
  const weights = R.pluck("weight", composition);
  const router = new Contract(
    addresses.uniswapRouter,
    routerArtifact.abi,
    signer
  );
  const amounts = await computeTargetWeights(
    tokens,
    weights,
    router,
    "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
    "0xe9e7cea3dedca5984780bafc599bd69add087d56",
    expandTo18Decimals(1).div(100000)
  );
  console.log(
    "calulated amounts",
    amounts.map((i) => i.toString())
  );
  const index = await indexFactory.deploy(
    tokens,
    amounts,
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
