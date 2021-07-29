import { getAddresses, isCallingScript } from "./utils";

import { ethers } from "hardhat";
import { updateAddresses } from "./deploy-all";

const main = async () => {
	const migratorFactory = await ethers.getContractFactory("IndexMigration");
	const addresses = getAddresses();
	const migrator = await migratorFactory.deploy(10, { gasPrice: 5000000001 });
	console.log("deployed migrator", migrator.address);
	addresses.indexMigration = migrator.address;
	updateAddresses(addresses);
	return migrator.address;
};

if (isCallingScript(__filename)) {
	main()
		.then(() => process.exit(0))
		.catch((err) => {
			console.error(err);
			process.exit(1);
		});
}

export default main;
