import "contracts/stacking/Masterchef.sol";
import "contracts/core/AUpdatable.sol";

contract TopChef is MasterChef, AUpdatable {
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
    }
}
