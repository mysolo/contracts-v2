import { expandTo18Decimals, getAddresses } from "./utils";

import { ethers } from "hardhat";

const main = async () => {
  const [dev] = await ethers.getSigners();
  const topChefFactory = await ethers.getContractFactory("TopChef");
  const addresses = getAddresses();
  const topChef = await topChefFactory.deploy(
    addresses.tokens.LEV,
    dev.address,
    expandTo18Decimals(4),
    0,
    0
  );
  console.log("Deployed TopChef", topChef.address);
  return topChef.address;
};

export default main;
