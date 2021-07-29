import { getAddresses, isCallingScript } from "./utils";

import { ethers } from "hardhat";
import { getContract } from "./contracts";

const main = async () => {
	const directoryFactory = await ethers.getContractFactory("IndexDirectory");
	const directory = await directoryFactory.deploy();
	console.log("Deployed directory", directory.address);
	return directory.address;
};

export const registerIndex = async (index: string) => {
	const directory = await getContract("IndexDirectory", getAddresses().directory);
	const tx = await directory.registerIndex(index);
	console.log("done");
	return tx.wait();
}

export const unregisterIndex = async (index: string) => {
	const directory = await getContract("IndexDirectory", getAddresses().directory);
	const tx = await directory.unregisterIndex(index);
	console.log("done");
	return tx.wait();
}


registerIndex(getAddresses().indexes.LI).then();


if (false && isCallingScript(__filename))
	main()
		.then(() => process.exit(0))
		.catch((error) => {
			console.error(error);
			process.exit(1);
		});

export default main;
