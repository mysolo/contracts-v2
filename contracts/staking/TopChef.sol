// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "contracts/staking/MasterChef.sol";
import "contracts/core/AUpdatable.sol";

contract TopChef is MasterChef, AUpdatable {
    event RewardUpdated(uint256 sushiPerBlock);

    constructor(
        IMasterchefToken _sushi,
        address _devaddr,
        uint256 _sushiPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    )
        MasterChef(
            _sushi,
            _devaddr,
            _sushiPerBlock,
            _startBlock,
            _bonusEndBlock
        )
    {}

    function changeSushiPerBlock(uint256 _sushiPerBlock) public onlyOwner {
        massUpdatePools();
        sushiPerBlock = _sushiPerBlock;
        emit RewardUpdated(sushiPerBlock);
    }
}
