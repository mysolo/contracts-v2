import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/team/TokenSharing.sol";
import "contracts/pancakeswap/PancakeswapUtilities.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

abstract contract FeesController is Ownable {
    IERC20[] _tokens;
    TokenSharing _tokenSharing;
    IERC20 _rewardToken;
    IUniswapV2Router02 _router;
    uint16 _rewardPerThousand;
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
        require(
            rewardPerThousand + buyBackPerThousand <= 1000,
            "FeesController : Reward + buyback must be < 100%."
        );
        _rewardPerThousand = rewardPerThousand;
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

    function changeReward(uint16 rewardPerThousand) external virtual onlyOwner {
        require(
            rewardPerThousand + _buyBackPerThousand <= 1000,
            "FeesController : Reward + buyback must be < 100%."
        );
        _rewardPerThousand = rewardPerThousand;
    }

    function changeBuyback(uint16 buyBackPerThousand)
        external
        virtual
        onlyOwner
    {
        require(
            _rewardPerThousand + buyBackPerThousand <= 1000,
            "FeesController : Reward + buyback must be < 100%."
        );
        _buyBackPerThousand = buyBackPerThousand;
    }

    function addToken(address token) external virtual onlyOwner {
        _tokens.push(IERC20(token));
    }

    function removeToken(address token) external virtual onlyOwner {
        for (uint256 i = 0; i < _tokens.length - 1; i++) {
            if (address(_tokens[i]) == token) {
                _tokens[i] = _tokens[_tokens.length - 1];
                delete _tokens[_tokens.length - 1];
                return;
            }
        }
    }

    function distribute() external virtual {
        for (uint16 i; i < _tokens.length; i++) {
            IERC20 token = _tokens[i];
            PancakeswapUtilities.sellToken(
                address(token),
                address(_rewardToken),
                address(this),
                token.balanceOf(address(this)),
                _router
            );
        }
        uint256 balance = _rewardToken.balanceOf(address(this));
        uint256 callerReward = (balance * _rewardPerThousand) / 1000;
        uint256 buybackAmount = (balance * _buyBackPerThousand) / 1000;
        uint256 teamReward = balance - callerReward - buybackAmount;
        _rewardToken.transfer(msg.sender, callerReward);
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

    function estimatedReward() external view virtual returns (uint256) {
        uint256 bnbValue = 0;
        for (uint16 i; i < _tokens.length; i++) {
            bnbValue += getTokenQuote(
                address(_tokens[i]),
                _tokens[i].balanceOf(address(this))
            );
        }
        return (bnbValue * _rewardPerThousand) / 1000;
    }

    function getTokenQuote(address token, uint256 amount)
        private
        view
        returns (uint256)
    {
        if (token == address(_WBNB)) return amount;
        address pairAddr = _factory.getPair(address(_WBNB), token);
        require(pairAddr != address(0), "Cannot find pair BNB-token");
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddr);
        (uint256 reserveBNB, uint256 reserveToken) = PancakeswapUtilities
        .getReservesOrdered(pair, address(_WBNB), token);
        return _router.getAmountIn(amount, reserveBNB, reserveToken);
    }
}
