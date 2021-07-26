import { getAddresses, isCallingScript } from "./utils";

import { ethers } from "hardhat";
import { getContract } from "./contracts";

const main = async (lpToken: string) => {
  const topChef = await getContract("TopChef", getAddresses().topChef);
  const tx = await topChef.add(1000, lpToken, false);
  await tx.wait();
  console.log("Pool added.");
};

if (isCallingScript(__filename))
  main(getAddresses().tokens.LEV)
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });

export default main;
