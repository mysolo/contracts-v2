import { ethers, network } from "hardhat";
import { expandTo18Decimals, getAddresses, isCallingScript } from "./utils";

import deployExchanger from "./deploy-exchanger";
import deployIndex from "./deploy-index";
import deployIndexToken from "./deploy-index-token";
import fs from "fs";
import { getContract } from "./contracts";

const env = network.name;
const addresses = getAddresses();

const updateAddresses = (nextAddresses: any) => {
  const oldAddresses = JSON.parse(
    fs.readFileSync("./scripts/addresses.json").toString()
  );
  const newAddresses = {
    ...oldAddresses,
    [env]: {
      ...oldAddresses[env],
      ...nextAddresses,
    },
  };
  fs.writeFileSync(
    "./scripts/addresses.json",
    JSON.stringify(newAddresses, null, 2)
  );
  return newAddresses;
};

const main = async () => {
  const exchanger = await deployExchanger();
  const indexToken = await deployIndexToken("LegacyIndex", "LI");
  const index = await deployIndex(
    [
      {
        token: "0x2170ed0880ac9a755fd29b2688956bd959f933f8",
        amount: expandTo18Decimals(1),
      },
      {
        token: "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82",
        amount: expandTo18Decimals(8),
      },
    ],
    exchanger,
    indexToken
  );
  const indexTokenContract = await getContract("IndexToken", indexToken);
  const tx = await indexTokenContract.transferOwnership(index);
  await tx.wait();

  return updateAddresses({
    exchanger,
    indexToken,
    index,
  });
};

if (isCallingScript(__filename))
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });

export default main;
