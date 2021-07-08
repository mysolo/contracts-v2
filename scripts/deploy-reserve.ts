import { ethers } from "hardhat";

const main = async () => {
  const reserveFactory = await ethers.getContractFactory("Reserve");
  const reserve = await reserveFactory.deploy([]);
  console.log("Deployed reserve", reserve.address);
  return reserve.address;
};

export default main;
