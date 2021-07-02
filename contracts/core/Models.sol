// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

library Models {

	struct TokenOrder {
		address token;
		bytes callData;
	}

	struct IndexComposition {
		address token;
		uint256 amount;
		uint256 targetWeight;
	}
}