import deployExchanger from "./deploy-exchanger";
import deployIndex from "./deploy-index";
import deployIndexToken from "./deploy-index-token";
import { ethers } from "hardhat";
import { expandTo18Decimals } from "./utils";
import { getContract } from "./contracts";

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
  return {
    exchanger,
    indexToken,
    index,
  };
};

export default main;
