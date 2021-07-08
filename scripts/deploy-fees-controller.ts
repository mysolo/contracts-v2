import { ethers } from "hardhat";
import { getAddresses } from "./utils";

const main = async (buybackPerThousand: number) => {
  const feeControllerFactory = await ethers.getContractFactory(
    "FeesController"
  );
  const feeController = await feeControllerFactory.deploy(
    buybackPerThousand,
    getAddresses().tokenSharing,
    getAddresses().tokens.WETH,
    getAddresses().tokens.LEV,
    getAddresses().uniswapRouter
  );
  return feeController.address;
};

export default main;
