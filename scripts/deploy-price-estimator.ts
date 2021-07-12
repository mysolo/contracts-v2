import { ethers } from "hardhat";
import { expandTo18Decimals } from "./utils";

const main = async (index: string) => {
  const priceEstimatorContractFactory = await ethers.getContractFactory(
    "IndexPriceEstimator"
  );
  const contract = await priceEstimatorContractFactory.deploy(
    "0x10ED43C718714eb63d5aA57B78B54704E256024E"
  );
  const resp = await contract.getIndexQuote(index, expandTo18Decimals(1));
  console.log(resp.toString());
};

main("0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154");
export default main;
