// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TokenExchanger.sol";
import "./Reserve.sol";
import "./FeesController.sol";
import "contracts/models/TokenOrder.sol";
import "contracts/models/IndexComposition.sol";
import "contracts/core/AIndex.sol";
import "contracts/tokens/WETH.sol";

// import "hardhat/console.sol";

contract Index is AIndex, ReentrancyGuard {
  IndexComposition[] public composition;
  Reserve public reserve;
  FeesController public feeTo;
  uint256 feePercentage;
  TokenExchanger public tokenExchanger;
  WETH private immutable _WETH;

  event IndexPurchased(address to, uint256 amount);
  event IndexSold(address from, uint256 amountIn);
  event TokenAdded(address token, uint256 amount);
  event TokenRemoved(address token);
  event TokenAmountChanged(address token, uint256 amount);
  event ReserveChanged(address reserve);
  event FeeToChanged(address feeTo);
  event FeePercentageChanged(uint256 feePercentage);
  event TokenExchangerChanged(address tokenExchanger);

  constructor(
    address[] memory tokens,
    uint256[] memory amounts,
    TokenExchanger _tokenExchanger,
    AIndexToken _indexToken,
    Reserve _reserve,
    WETH WETH_,
    FeesController _feeTo,
    uint256 _feePercentage // 10e4
  ) AIndex(_indexToken) {
    for (uint256 i = 0; i < tokens.length; i++)
      composition.push(IndexComposition(tokens[i], amounts[i], 0));
    reserve = _reserve;
    tokenExchanger = _tokenExchanger;
    _WETH = WETH_;
    feeTo = _feeTo;
    feePercentage = _feePercentage;
  }

  receive() external payable {}

  function getComposition() external view returns (IndexComposition[] memory) {
    return composition;
  }

  function setReserve(Reserve newReserve) external onlyOwner {
    reserve = newReserve;
    emit ReserveChanged(address(newReserve));
  }

  function setFeeTo(FeesController newFeeTo) external onlyOwner {
    feeTo = newFeeTo;
    emit FeeToChanged(address(newFeeTo));
  }

  function setFeePercentage(uint256 _feePercentage) external onlyOwner {
    feePercentage = _feePercentage;
    emit FeePercentageChanged(_feePercentage);
  }

  function setTokenExchanger(TokenExchanger newTokenExchanger)
    external
    onlyOwner
  {
    tokenExchanger = newTokenExchanger;
    emit TokenExchangerChanged(address(newTokenExchanger));
  }

  function purchaseIndex(
    IERC20 sellToken,
    uint256 amountIn,
    uint256 minAmountOut,
    address payable swapTarget,
    TokenOrder[] calldata tokenOrders
  ) external payable nonReentrant {
    require(tokenOrders.length > 0, "BUY_ARG_MISSING");

    bool isSellTokenETH = address(sellToken) ==
      0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    if (isSellTokenETH) sellToken = IERC20(address(_WETH));

    uint256 exchangerBalanceBefore = sellToken.balanceOf(
      address(tokenExchanger)
    );

    uint256 fees = (amountIn * feePercentage) / 1000;

    if (!isSellTokenETH) {
      // todo use safe transferfrom
      sellToken.transferFrom(
        msg.sender,
        address(tokenExchanger),
        amountIn + fees
      );
    } else {
      _WETH.deposit{ value: amountIn + fees }();
      _WETH.transfer(address(tokenExchanger), amountIn + fees);
    }

    uint256 boughtAmount = _purchaseUnderlyingAssets(
      minAmountOut,
      sellToken,
      swapTarget,
      tokenOrders
    );

    _indexToken.mint(msg.sender, boughtAmount);

    if (fees > 0) tokenExchanger.payFee(sellToken, feeTo, fees);

    // refund the user for the sell token that hasn't been used in trades
    uint256 exchangerBalanceAfter = sellToken.balanceOf(
      address(tokenExchanger)
    );
    uint256 refundAmount = exchangerBalanceAfter - exchangerBalanceBefore;
    payUser(sellToken, refundAmount, isSellTokenETH);

    emit IndexPurchased(msg.sender, boughtAmount);
  }

  function _purchaseUnderlyingAssets(
    uint256 amountOut, /* todo: rename */
    IERC20 sellToken,
    address payable swapTarget,
    TokenOrder[] calldata tokenOrders
  ) private returns (uint256) {

    require(tokenOrders.length == composition.length, "WRONG_ORDERS_LENGTH");

      uint256 minIndexAmountPurchased /* todo: rename */
     = type(uint256).max;

    for (uint256 i = 0; i < tokenOrders.length; i++) {
      IERC20 token = IERC20(composition[i].token);
      uint256 amountBought = 0;

      if (token == sellToken) {
        uint256 amount = (amountOut * composition[i].amount) / 1e18;
        tokenExchanger.transfer(token, amount, address(reserve));
        amountBought = amount;
      } else {
        amountBought = tokenExchanger.executeTrade(
          sellToken,
          IERC20(composition[i].token),
          swapTarget,
          tokenOrders[i].callData,
          address(reserve)
        );
      }

      uint256 indexAmountPurchased = (amountBought * 1e18) /
        composition[i].amount;
      if (indexAmountPurchased < minIndexAmountPurchased)
        minIndexAmountPurchased = indexAmountPurchased;
    }

    /* todo: make slippage dynamic */
    require(
      minIndexAmountPurchased >= (amountOut * 99) / 100,
      "BOUGHT_TOO_LITTLE"
    );
    return minIndexAmountPurchased;
  }

  function sellIndex(
    IERC20 buyToken,
    uint256 amountIn,
    uint256 minAmountOut,
    address payable swapTarget,
    TokenOrder[] calldata tokenOrders
  ) external nonReentrant {
    require(tokenOrders.length > 0, "BUY_ARGS_MISSING");
    _indexToken.burn(msg.sender, amountIn);

    bool isBuyTokenETH = address(buyToken) ==
      0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    if (isBuyTokenETH) buyToken = IERC20(address(_WETH));

    uint256 saleAmount = _sellUnderlyingAssets(
      amountIn,
      buyToken,
      swapTarget,
      tokenOrders
    );
    uint256 fees = (saleAmount * feePercentage) / 1000;
    if (fees > 0) tokenExchanger.payFee(buyToken, feeTo, fees);

    uint256 refund = 0;
    uint256 amountOut = saleAmount + refund - fees;
    require(amountOut >= minAmountOut, "AMOUNT_OUT_TOO_LOW");

    payUser(buyToken, amountOut, isBuyTokenETH);

    emit IndexSold(msg.sender, amountIn);
  }

  function _sellUnderlyingAssets(
    uint256 amountOut,
    IERC20 buyToken,
    address payable swapTarget,
    TokenOrder[] calldata tokenOrders
  ) private returns (uint256) {
    uint256 totalSaleAmount = 0;

    for (uint256 i = 0; i < tokenOrders.length; i++) {
      IERC20 sellToken = IERC20(composition[i].token);
      uint256 amount = (amountOut * composition[i].amount) / 1e18; /* dynamic decimals? */

      reserve.transfer(sellToken, amount, address(tokenExchanger));

      uint256 amountBought = amount;
      if (address(buyToken) != composition[i].token)
        amountBought = tokenExchanger.executeTrade(
          sellToken,
          buyToken,
          swapTarget,
          tokenOrders[i].callData,
          address(tokenExchanger)
        );
      totalSaleAmount += amountBought;
      require(amountBought > 0, "SWAP_CALL_FAILED");
    }

    return totalSaleAmount;
  }

  function getTokenIndex(IERC20 token) public view returns (uint32) {
    for (uint32 i = 0; i < composition.length; i++)
      if (composition[i].token == address(token)) return i;
    revert("TOKEN_NOT_FOUND");
  }

  function setTokenAmount(IERC20 token, uint256 amount) external onlyOwner {
    if (amount == 0) return removeToken(token);
    composition[getTokenIndex(token)].amount = amount;

    emit TokenAmountChanged(address(token), amount);
  }

  function removeToken(IERC20 token) public onlyOwner {
    require(!reserve.hasToken(token), "EMPTY_RESERVE_FIRST");
    uint32 index = getTokenIndex(token);
    composition[index] = composition[composition.length - 1];
    delete composition[composition.length - 1];

    emit TokenRemoved(address(token));
  }

  function addToken(IERC20 token, uint256 amount) external onlyOwner {
    require(
      token.balanceOf(address(reserve)) >= amount,
      "ADD_TOKEN_NOT_FUNDED"
    );
    composition.push(IndexComposition(address(token), amount, 0));

    emit TokenAdded(address(token), amount);
  }

  function payUser(
    IERC20 token,
    uint256 amount,
    bool unwrapEther
  ) private {
    if (unwrapEther) {
      tokenExchanger.transfer(IERC20(address(_WETH)), amount, address(this));
      _WETH.withdraw(amount);
      (bool success, ) = msg.sender.call{ value: amount }("");
      require(success, "ETH_TRANSFER_ERROR");
    } else tokenExchanger.transfer(token, amount, msg.sender);
  }

  function update(address newContract)
    public
    virtual
    override
    onlyOwner
    onlyUpToDate
  {
    super.update(newContract);
    reserve.addManager(newContract);
    reserve.removeManager(address(this));
  }

  /*
   ** If something's wrong with the LPs or anything else, anyone can
   ** withdraw the index underlying tokens directly to their wallets
   */
  function emergencyWithdraw() external nonReentrant {
    uint256 userBalance = _indexToken.balanceOf(msg.sender);

    for (uint256 i = 0; i < composition.length; i++) {
      uint256 entitledAmount = (userBalance * composition[i].amount) / 1e18;
      ERC20 token = ERC20(composition[i].token);
      uint256 indexBalance = token.balanceOf(address(reserve));
      // should never happen!
      if (indexBalance < entitledAmount) entitledAmount = indexBalance;
      reserve.transfer(token, entitledAmount, msg.sender);
    }
    _indexToken.burn(msg.sender, userBalance);
  }
}
