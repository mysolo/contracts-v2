import { ethers, network } from "hardhat";
import { expandTo18Decimals, getAddresses, isCallingScript } from "./utils";

import addStakingPool from "./add-staking-pool";
import { updateAddresses } from "./deploy-all";

const env = network.name;

const main = async () => {
  const [signer] = await ethers.getSigners();
  const topChefFactory = await ethers.getContractFactory("TopChef");
  const addresses = getAddresses();
  const topChef = await topChefFactory.deploy(
    addresses.tokens.LEV,
    signer.address,
    0,
    0,
    0
  );
  console.log("deployed topchef", topChef.address);
  addresses.topChef = topChef.address;
  await addStakingPool(addresses.tokens.LEV);
  updateAddresses(addresses);
  return topChef.address;
};

if (isCallingScript(__filename)) {
  main()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}

export default main;
