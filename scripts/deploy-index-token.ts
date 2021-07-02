import { ethers } from "hardhat";

const main = async (name: string, symbol: string) => {
  const indexTokenFactory = await ethers.getContractFactory("IndexToken");
  const indexToken = await indexTokenFactory.deploy(name, symbol);
  console.log("Deployed index token", indexToken.address);
  return indexToken.address;
};

export default main;
