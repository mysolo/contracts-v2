import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/team/TokenSharing.sol";
import "contracts/pancakeswap/PancakeswapUtilities.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

abstract contract FeesController is Ownable {
    TokenSharing _tokenSharing;
    IUniswapV2Router02 _router;
    IERC20 _rewardToken;
    uint16 _buyBackPerThousand;
    IERC20 _LEV;
    IERC20 _WBNB;
    IUniswapV2Factory _factory;

    constructor(
        uint16 rewardPerThousand,
        uint16 buyBackPerThousand,
        address tokenSharing,
        IERC20 LEV,
        IUniswapV2Router02 router,
        IUniswapV2Factory factory,
        IERC20 WBNB
    ) {
        _buyBackPerThousand = buyBackPerThousand;
        _tokenSharing = TokenSharing(tokenSharing);
        _router = router;
        _LEV = LEV;
        _WBNB = WBNB;
        _factory = factory;
    }

    function changeRewardToken(IERC20 rewardToken) external virtual onlyOwner {
        _rewardToken = rewardToken;
    }

    function changeBuyback(uint16 buyBackPerThousand)
        external
        virtual
        onlyOwner
    {
        require(
            buyBackPerThousand <= 1000,
            "FeesController : buyback must be <= 100%."
        );
        _buyBackPerThousand = buyBackPerThousand;
    }

    function pay(IERC20 originToken, uint256 amount) external virtual {
        PancakeswapUtilities.sellToken(
            address(originToken),
            address(_rewardToken),
            address(this),
            amount,
            _router
        );
        uint256 balance = _rewardToken.balanceOf(address(this));
        uint256 buybackAmount = (balance * _buyBackPerThousand) / 1000;
        uint256 teamReward = balance - buybackAmount;
        _rewardToken.transfer(address(_tokenSharing), teamReward);
        PancakeswapUtilities.sellToken(
            address(_rewardToken),
            address(_LEV),
            address(this),
            buybackAmount,
            _router
        );
        _LEV.transfer(address(0), _LEV.balanceOf(address(this)));
    }
}
