// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "contracts/staking/MasterChef.sol";
import "contracts/core/AUpdatable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TopChef is MasterChef, AUpdatable {
  constructor(
    IMasterchefToken _sushi,
    address _devaddr,
    uint256 _sushiPerBlock,
    uint256 _startBlock,
    uint256 _bonusEndBlock
  ) MasterChef(_sushi, _devaddr, _sushiPerBlock, _startBlock, _bonusEndBlock) {}

  function changeSushiPerBlock(uint256 _sushiPerBlock) public onlyOwner {
    massUpdatePools();
    sushiPerBlock = _sushiPerBlock;
  }

  function update(address newContract) public override onlyOwner {
    for (uint16 i = 0; i < poolInfo.length; i++) set(i, 0, false);
    massUpdatePools();
    Ownable(address(sushi)).transferOwnership(newContract);
  }
}
