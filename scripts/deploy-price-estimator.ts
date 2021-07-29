import { expandTo18Decimals, getAddresses } from "./utils";

import { ethers } from "hardhat";
import { getContract } from "./contracts";

const main = async (index: string) => {
  const priceEstimatorContractFactory = await ethers.getContractFactory(
    "IndexPriceEstimator"
  );
  //  const contract = await priceEstimatorContractFactory.deploy(
  //    getAddresses().uniswapRouter
  //  );

  console.log("index:", index);
  console.log("amount:", expandTo18Decimals(1).toString());
  console.log("estimator address", getAddresses().priceEstimator);
  const contract = await getContract("IndexPriceEstimator", getAddresses().priceEstimator);
  const resp = await contract.getIndexQuote(index, expandTo18Decimals(1));
  console.log(resp.toString());
};

export default main;
