import { expandTo18Decimals, getAddresses } from "./utils";

import { ethers } from "hardhat";
import { getContract } from "./contracts";

const main = async (index: string) => {
  const priceEstimatorContractFactory = await ethers.getContractFactory(
    "IndexPriceEstimator"
  );
  const contract = await priceEstimatorContractFactory.deploy(
    getAddresses().uniswapRouter
  );
  const resp = await contract.getIndexQuote(index, expandTo18Decimals(1));
  console.log(resp.toString());
};

main(getAddresses().indexes.LI);
export default main;
