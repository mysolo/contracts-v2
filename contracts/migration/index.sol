import "contracts/v1/IIndexPool.sol";
import "contracts/indexes/Index.sol";
import "contracts/core/AUpdatable.sol";
import "contracts/interfaces/IWETH9.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IndexMigration is Ownable {
    uint8 _cashbackPerThousand;

    constructor(uint8 cashbackPerThousand) {
        updateCashback(cashbackPerThousand);
    }

    function withdrawCashback() external payable onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "ETH_TRANSFER_ERROR");
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
            tx.origin == msg.sender || _cashbackPerThousand == 0,
            "IndexMigration : Migration with cashback is forbbiden for contracts."
        );
        uint256 amountToSell = indexV1.balanceOf(msg.sender);
        indexV1.transferFrom(msg.sender, address(this), amountToSell);
        uint256 ethAmount = indexV1.sellIndex(amountToSell, minAmountSell);
        ethAmount += (ethAmount * _cashbackPerThousand) / 1000;
        require(
            address(this).balance >= ethAmount,
            "IndexMigration : Insufficent balance to cashback the user."
        );
        indexV2.purchaseIndex(
            IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            ethAmount,
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
