import { ethers, network } from "hardhat";
import { expandTo18Decimals, getAddresses, isCallingScript } from "./utils";

import deployExchanger from "./deploy-exchanger";
import deployFeesController from "./deploy-fees-controller";
import deployIndex from "./deploy-index";
import deployIndexToken from "./deploy-index-token";
import deployReserve from "./deploy-reserve";
import deployTopChef from "./top-masterchef";
import fs from "fs";
import { getContract } from "./contracts";
import recoverLevOwnership from "./recover-lev-ownership";

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
  const reserve = await deployReserve();
  const feeController = await deployFeesController(750);
  const index = await deployIndex(
    [
      {
        token: "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c",
        weight: 300,
      },
      {
        token: "0x2170ed0880ac9a755fd29b2688956bd959f933f8",
        weight: 200,
      },
      {
        token: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
        weight: 150,
      },
      {
        token: "0x7083609fce4d1d8dc0c979aab8c869ea2c873402",
        weight: 50,
      },
      {
        token: "0xf8a0bf9cf54bb92f17374d9e9a321e6a111a51bd",
        weight: 50,
      },
      {
        token: "0x3ee2200efb3400fabb9aacf31297cbdd1d435d47",
        weight: 50,
      },
      {
        token: "0x4338665cbb7b2485a8855a139b75d5e34ab0db94",
        weight: 50,
      },
      {
        token: "0x0eb3a705fc54725037cc9e008bdede697f62f335",
        weight: 50,
      },
      {
        token: "0xbf5140a22578168fd562dccf235e5d43a02ce9b1",
        weight: 50,
      },
      {
        token: "0x8ff795a6f4d97e7887c79bea79aba5cc76444adf",
        weight: 50,
      },
    ],
    exchanger,
    indexToken,
    reserve,
    feeController
  );
  const reserveContract = await getContract("Reserve", reserve);
  await reserveContract.addManager(index);
  const indexTokenContract = await getContract("IndexToken", indexToken);
  const tx = await indexTokenContract.transferOwnership(index);
  await tx.wait();
  const exchangerContract = await getContract("TokenExchanger", exchanger);
  await exchangerContract.registerIndex(index);

  //const topChef = await deployTopChef();
  //await recoverLevOwnership(topChef);

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
