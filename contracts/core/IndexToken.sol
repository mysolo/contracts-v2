// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "./AIndexToken.sol";

contract IndexToken is AIndexToken {

	constructor(string memory name, string memory symbol) AIndexToken(name, symbol) {}
}
