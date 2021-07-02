import { ethers } from "hardhat";

export const getContract = async (name: string, address: string) => {
  const factory = await ethers.getContractFactory(name);
  return factory.attach(address);
};
