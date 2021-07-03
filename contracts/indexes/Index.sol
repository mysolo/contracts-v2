// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TokenExchanger.sol";
import "contracts/models/TokenOrder.sol";
import "contracts/models/IndexComposition.sol";
import "contracts/core/AIndex.sol";
import "contracts/tokens/WETH.sol";

import "hardhat/console.sol";

contract Index is AIndex {

	IndexComposition[] public composition;
	address public reserve;
	address public feeTo;
	TokenExchanger public tokenExchanger;
    WETH private immutable _WETH;

	constructor(address[] memory tokens, uint256[] memory amounts, TokenExchanger _tokenExchanger, AIndexToken _indexToken, WETH WETH_, address _feeTo)
		AIndex(_indexToken) {

		for (uint256 i = 0; i < tokens.length; i++)
			composition.push(IndexComposition(tokens[i], amounts[i], 0));
		reserve = address(this);
		tokenExchanger = _tokenExchanger;
		_WETH = WETH_;
		feeTo = _feeTo;
	}

	function getComposition() external view returns (IndexComposition[] memory) {
		return composition;
	}

	function purchaseIndex(
		IERC20 sellToken,
		uint256 amountIn,
		uint256 minAmountOut,
		address payable swapTarget,
		TokenOrder[] calldata tokenOrders) external payable {

		require(tokenOrders.length > 0, "BUY_ARG_MISSING");

		if (true || address(sellToken) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
			sellToken = IERC20(address(_WETH));
  	       _WETH.deposit{value: msg.value}();
		} else {
			// todo use safe transferfrom
			sellToken.transferFrom(msg.sender, address(tokenExchanger), amountIn);
		}

		// todo make updatable, possibly add VIP tiers
		uint256 fees = amountIn / 100;
		uint256 amountInWithFees = amountIn + fees;

		// todo use safetransferfrom
		sellToken.transfer(address(tokenExchanger), amountIn);

		uint256 boughtAmount = _purchaseUnderlyingAssets(minAmountOut, sellToken, swapTarget, tokenOrders);

		_indexToken.mint(msg.sender, boughtAmount);
		// todo: take fee
	}

	/* todo allow to withdraw dusts */
	function _purchaseUnderlyingAssets(uint256 amountOut /* todo: rename */, IERC20 sellToken, address payable swapTarget, TokenOrder[] calldata tokenOrders)
		private returns (uint256) {

		uint256 minIndexAmountPurchased /* todo: rename */ = type(uint256).max;

     	for (uint256 i = 0; i < tokenOrders.length; i++) {
        	uint256 amountBought = tokenExchanger.executeTrade(sellToken, IERC20(composition[i].token), swapTarget, tokenOrders[i].callData, reserve);
			uint256 indexAmountPurchased /* todo rename */ = (amountBought * 1e18) / composition[i].amount;
			console.log("token ", composition[i].token, "bought", amountBought);
			if (indexAmountPurchased < minIndexAmountPurchased)
				minIndexAmountPurchased = indexAmountPurchased;
		}

		console.log("bought", minIndexAmountPurchased);
		/* todo: make slippage dynamic */
		require(minIndexAmountPurchased >= amountOut * 99 / 100, "BOUGHT_TOO_LITTLE");
		return minIndexAmountPurchased;
	}

	function sellIndex(IERC20 buyToken, uint256 amountOut, address payable swapTarget, TokenOrder[] calldata tokenOrders) external {
		require(tokenOrders.length > 0, "BUY_ARGS_MISSING");
		require(amountOut <= _indexToken.balanceOf(msg.sender), "INSUFFICIENT_BALANCE");

		uint256 soldAmount = _sellUnderlyingAssets(amountOut, buyToken, swapTarget, tokenOrders);
		_indexToken.burn(msg.sender, soldAmount);
	}

	function _sellUnderlyingAssets(uint256 amountOut, IERC20 buyToken, address payable swapTarget, TokenOrder[] calldata tokenOrders) private returns (uint256) {
		uint256 minIndexAmountSold /* todo: rename */ = type(uint256).max;

		for (uint256 i = 0; i < tokenOrders.length; i++) {

			IERC20 sellToken = IERC20(composition[i].token);

			// todo use reserve
			sellToken.transfer(address(tokenExchanger), amountOut * composition[i].amount / 1e18 /* dynamic decimals? */);

			uint256 amountSold = tokenExchanger.executeTrade(
				sellToken, buyToken, swapTarget, tokenOrders[i].callData, address(msg.sender)
			);
			uint256 indexAmountSold /* todo rename */ = (amountSold * 1e18 /* different decimals? */) / composition[i].amount;
			require(indexAmountSold > 0, "SWAP_CALL_FAILED");
			if (indexAmountSold < minIndexAmountSold)
				minIndexAmountSold = indexAmountSold;
		}

		return amountOut;
	}

	function update(address newContract) public override {
		super.update(newContract);
	}
}