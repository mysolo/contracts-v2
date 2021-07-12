import { ethers, network } from "hardhat";

import { Contract } from "ethers";
import { Interface } from "ethers/lib/utils";
import { getAddresses } from "./utils";
import { getContract } from "./contracts";

const main = async (topChef: string) => {
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: ["0x16149999C85c3E3f7d1B9402a4c64d125877d89D"],
  });
  const signer = ethers.provider.getSigner(
    "0x16149999C85c3E3f7d1B9402a4c64d125877d89D"
  );

  const addresses = getAddresses();
  const lev = await getContract("LEVToken", addresses.tokens.LEV);
  const abi = [
    "function recoverLevOwnership()",
    "function owner() view returns (address)",
  ];

  await network.provider.send("hardhat_setBalance", [
    "0x16149999C85c3E3f7d1B9402a4c64d125877d89D",
    "0x10000000000000000",
  ]);

  const iface = new Interface(abi);
  const masterchefv1 = new Contract(addresses.masterChefv1, iface, signer);

  const tx = await masterchefv1.connect(signer).recoverLevOwnership();
  await tx.wait();
  await lev.connect(signer).transferOwnership(topChef);
};

export default main;
