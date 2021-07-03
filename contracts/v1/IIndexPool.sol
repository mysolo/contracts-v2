import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IIndexPool is IERC20 {
    /*
     ** purchase at least amountOut of the index paying with a BEP20 token
     */
    function buyIndexWith(
        uint256 amountOut,
        address paymentToken,
        uint256 amountInMax
    ) external;

    /*
     ** purchase at least amountOut of the index paying with BNB
     */
    function buyIndex(uint256 amountOut) external payable;

    function sellIndex(uint256 amount, uint256 amountOutMin)
        external
        returns (uint256);

    receive() external payable;

    // get the total price of the index in BNB (from Pancakeswap)
    function getIndexQuote(uint256 amount) external returns (uint256);

    function getIndexQuoteWithFee(uint256 amount) external returns (uint256);

    function getFee(uint256 amount) external pure returns (uint256);

    // get the price of a token in BNB (from Pancakeswap)
    function getTokenQuote(address token, uint256 amount)
        external
        view
        returns (uint256);

    function getComposition()
        external
        view
        returns (address[] memory, uint16[] memory);

    function changeWeights(uint16[] memory weights) external;

    /*
     ** If something's wrong with the LPs or anything else, anyone can
     ** withdraw the index underlying tokens directly to their wallets
     */
    function emergencyWithdraw() external;
}
