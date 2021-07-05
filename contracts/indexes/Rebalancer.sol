// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "contracts/core/AUpdatable.sol";
import "./Index.sol";

/**
 * This contract administrates an index token weights and underlying assets. Will be deployed and implemented later
 */
contract Rebalancer is AUpdatable {
  Index immutable index;

  constructor(Index _index) {
    index = _index;
  }

  function update(address nextContract) public override onlyOwner onlyUpToDate {
    super.update(nextContract);
  }
}
