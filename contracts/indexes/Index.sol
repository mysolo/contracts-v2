// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TokenExchanger.sol";
import "./Reserve.sol";
import "./FeesController.sol";
import "contracts/models/TokenOrder.sol";
import "contracts/models/IndexComposition.sol";
import "contracts/core/AIndex.sol";
import "contracts/tokens/WETH.sol";

import "hardhat/console.sol";

contract Index is AIndex {
  IndexComposition[] public composition;
  Reserve public reserve;
  FeesController public feeTo;
  TokenExchanger public tokenExchanger;
  WETH private immutable _WETH;

  event IndexPurchased(address to, uint256 amount);
  event IndexSold(address from, uint256 amount);
  event TokenAdded(address token, uint256 amount);
  event TokenRemoved(address token);
  event TokenAmountChanged(address token, uint256 amount);

  constructor(
    address[] memory tokens,
    uint256[] memory amounts,
    TokenExchanger _tokenExchanger,
    AIndexToken _indexToken,
    Reserve _reserve,
    WETH WETH_,
    FeesController _feeTo
  ) AIndex(_indexToken) {
    for (uint256 i = 0; i < tokens.length; i++)
      composition.push(IndexComposition(tokens[i], amounts[i], 0));
    reserve = reserve;
    tokenExchanger = _tokenExchanger;
    _WETH = WETH_;
    feeTo = _feeTo;
  }

  receive() external payable {}

  function getComposition() external view returns (IndexComposition[] memory) {
    return composition;
  }

  function setReserve(Reserve newReserve) external onlyOwner {
    reserve = newReserve;
  }

  function setFeeTo(FeesController newFeeTo) external onlyOwner {
    feeTo = newFeeTo;
  }

  function setTokenExchanger(TokenExchanger newTokenExchanger)
    external
    onlyOwner
  {
    tokenExchanger = newTokenExchanger;
  }

  function purchaseIndex(
    IERC20 sellToken,
    uint256 amountIn,
    uint256 minAmountOut,
    address payable swapTarget,
    TokenOrder[] calldata tokenOrders
  ) external payable {
    require(tokenOrders.length > 0, "BUY_ARG_MISSING");

    bool isSellTokenETH = address(sellToken) ==
      0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    if (isSellTokenETH) sellToken = IERC20(address(_WETH));

    uint256 exchangerBalanceBefore = sellToken.balanceOf(
      address(tokenExchanger)
    );

    // todo make updatable, possibly add VIP tiers
    uint256 fees = amountIn / 100;

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

    // refund the user for the sell token that hasn't been used in trades
    uint256 exchangerBalanceAfter = sellToken.balanceOf(
      address(tokenExchanger)
    );
    uint256 refundAmount = exchangerBalanceAfter - exchangerBalanceBefore;
    payUser(sellToken, refundAmount, isSellTokenETH);

    _indexToken.mint(msg.sender, boughtAmount);

    tokenExchanger.payFee(sellToken, feeTo, fees);

    console.log(sellToken.balanceOf(address(tokenExchanger)));
    emit IndexPurchased(msg.sender, boughtAmount);
  }

  /* todo allow to withdraw dusts */
  function _purchaseUnderlyingAssets(
    uint256 amountOut, /* todo: rename */
    IERC20 sellToken,
    address payable swapTarget,
    TokenOrder[] calldata tokenOrders
  ) private returns (uint256) {

      uint256 minIndexAmountPurchased /* todo: rename */
     = type(uint256).max;

    for (uint256 i = 0; i < tokenOrders.length; i++) {
      uint256 amountBought = tokenExchanger.executeTrade(
        sellToken,
        IERC20(composition[i].token),
        swapTarget,
        tokenOrders[i].callData,
        address(reserve)
      );

      uint256 indexAmountPurchased = (amountBought * 1e18) /
        composition[i].amount;
      console.log("token ", composition[i].token, "bought", amountBought);
      if (indexAmountPurchased < minIndexAmountPurchased)
        minIndexAmountPurchased = indexAmountPurchased;
    }

    console.log("bought", minIndexAmountPurchased);
    /* todo: make slippage dynamic */
    require(
      minIndexAmountPurchased >= (amountOut * 99) / 100,
      "BOUGHT_TOO_LITTLE"
    );
    return minIndexAmountPurchased;
  }

  function sellIndex(
    IERC20 buyToken,
    uint256 amountOut,
    address payable swapTarget,
    TokenOrder[] calldata tokenOrders
  ) external {
    require(tokenOrders.length > 0, "BUY_ARGS_MISSING");
    _indexToken.burn(msg.sender, amountOut);

    bool isBuyTokenETH = address(buyToken) ==
      0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    if (isBuyTokenETH) buyToken = IERC20(address(_WETH));

    uint256 saleAmount = _sellUnderlyingAssets(
      amountOut,
      buyToken,
      swapTarget,
      tokenOrders
    );

    uint256 fees = saleAmount / 100; // todo custom fee
    tokenExchanger.payFee(buyToken, feeTo, fees);

    uint256 refund = 0;
    payUser(buyToken, saleAmount + refund - fees, isBuyTokenETH);

    emit IndexSold(msg.sender, amountOut);
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

      reserve.transfer(
        sellToken,
        (amountOut * composition[i].amount) / 1e18, /* dynamic decimals? */
        address(tokenExchanger)
      );

      // when selling, sale amount is sent to this contract
      uint256 amountBought = tokenExchanger.executeTrade(
        sellToken,
        buyToken,
        swapTarget,
        tokenOrders[i].callData,
        address(this)
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

  // could happen in exchanger?
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
    } else token.transfer(msg.sender, amount);
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
}
