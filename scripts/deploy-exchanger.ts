import { ethers } from "hardhat";

const main = async () => {
  const exchangerFactory = await ethers.getContractFactory("TokenExchanger");
  const exchanger = await exchangerFactory.deploy();
  console.log("deployed exchanger", exchanger.address);
  return exchanger.address;
};

if (false)
  main()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });

export default main;
