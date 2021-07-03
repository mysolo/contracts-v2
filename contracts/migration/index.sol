import "contracts/v1/IIndexPool.sol";
import "contracts/indexes/Index.sol";
import "contracts/core/AUpdatable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IndexMigration is Ownable {
    IERC20 _WBNB;
    uint8 _cashbackPerThousand;

    constructor(IERC20 WBNB, uint8 cashbackPerThousand) {
        _WBNB = WBNB;
        updateCashback(cashbackPerThousand);
    }

    function withdrawCashback(uint8 cashbackPerThousand) external onlyOwner {
        _WBNB.transfer(msg.sender, _WBNB.balanceOf(address(this)));
    }

    function updateCashback(uint8 cashbackPerThousand) public onlyOwner {
        require(
            cashbackPerThousand <= 100,
            "IndexMigration : Cashback cant be more than 10%."
        );
        _cashbackPerThousand = cashbackPerThousand;
    }

    function migration(
        IIndexPool indexV1,
        Index indexV2,
        uint256 minAmountSell,
        uint256 minAmountReceive,
        address payable swapTarget,
        TokenOrder[] calldata tokenOrders
    ) public {
        require(
            tx.origin == msg.sender,
            "IndexMigration : Migration with cashback is forbbiden for contracts."
        );
        uint256 amountToSell = indexV1.balanceOf(msg.sender);
        indexV1.transferFrom(msg.sender, address(this), amountToSell);
        uint256 wbnbAmount = indexV1.sellIndex(amountToSell, minAmountSell);
        wbnbAmount += (wbnbAmount * _cashbackPerThousand) / 1000;
        require(
            _WBNB.balanceOf(address(this)) >= wbnbAmount,
            "IndexMigration : Insufficent WBNB balance to cashback the user."
        );
        indexV2.purchaseIndex(
            _WBNB,
            wbnbAmount,
            minAmountReceive,
            swapTarget,
            tokenOrders
        );
        uint256 amountBought = indexV2._indexToken().balanceOf(address(this));
        indexV2._indexToken().transfer(msg.sender, amountBought);
    }

    function migrationWithoutCashback(
        IIndexPool indexV1,
        Index indexV2,
        uint256 minAmountSell,
        uint256 minAmountReceive,
        address payable swapTarget,
        TokenOrder[] calldata tokenOrders
    ) external {
        uint8 savedCashback = _cashbackPerThousand;
        _cashbackPerThousand = 0;
        migration(
            indexV1,
            indexV2,
            minAmountSell,
            minAmountReceive,
            swapTarget,
            tokenOrders
        );
        _cashbackPerThousand = savedCashback;
    }
}
