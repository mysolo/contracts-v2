import "contracts/v1/IIndexPool.sol";
import "contracts/indexes/Index.sol";
import "contracts/core/AUpdatable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IndexMigration is Ownable {
    IERC20 _WBNB;
    uint8 _cashbackPerThouasant;

    constructor(IERC20 WBNB) {
        _WBNB = WBNB;
    }

    function uptdateCashback(uint8 cashbackPerThouasant) external onlyOwner {
        require(
            cashbackRate <= 100,
            "IndexMigration : Cashback cant be more than 10%."
        );
        _cashbackPerThouasant = cashbackPerThouasant;
    }

    function migration(
        IIndexPool indexV1,
        Index indexV2,
        uint256 minAmountOut,
        address payable swapTarget,
        TokenOrder[] calldata tokenOrders
    ) external {
        uint256 amountToSell = indexV1.balanceOf(msg.sender);
        indexV1.transferFrom(msg.sender, address(this), amountToSell);
        uint256 wbnbAmount = indexV1.sellIndex(amountToSell, 0); // 0 mint amount ? or we ask to the user ?
        wbnbAmount += (wbnbAmount * _cashbackPerThouasant) / 1000;
        require(
            _WBNB.balanceOf(address(this)) >= wbnbAmount,
            "IndexMigration : Insufficent WBNB balance to cashback the user."
        );
        uint256 amountBought = indexV2.purchaseIndex(
            _WBNB,
            wbnbAmount,
            minAmountOut,
            swapTarget,
            tokenOrders
        );
        indexV2.tranfer(amountBought, msg.sender);
    }
}
