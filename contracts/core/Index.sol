// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TokenExchanger.sol";
import "./Models.sol";
import "./AIndex.sol";
import "contracts/tokens/WETH.sol";

import "hardhat/console.sol";

contract Index is AIndex {

	Models.IndexComposition[] public composition;
	address public reserve;
	TokenExchanger public tokenExchanger;
    WETH private immutable _WETH;

	constructor(address[] memory tokens, uint256[] memory amounts, TokenExchanger _tokenExchanger, AIndexToken _indexToken, WETH WETH_)
		AIndex(_indexToken) {

		for (uint256 i = 0; i < tokens.length; i++)
			composition.push(Models.IndexComposition(tokens[i], amounts[i], 0));
		reserve = address(this);
		tokenExchanger = _tokenExchanger;
		_WETH = WETH_;
	}

	function getComposition() external view returns (Models.IndexComposition[] memory) {
		return composition;
	}

	function purchaseIndex(
		IERC20 sellToken,
		uint256 amountIn,
		uint256 exactAmountOut,
		address payable swapTarget,
		Models.TokenOrder[] calldata tokenOrders) external payable {

		require(tokenOrders.length > 0, "BUY_ARG_MISSING");

		if (true || address(sellToken) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
			sellToken = IERC20(address(_WETH));
  	       _WETH.deposit{value: msg.value}();
		}

		// todo make updatable, possibly add VIP tiers
		uint256 fees = amountIn / 100;
		uint256 amountInWithFees = amountIn + fees;

		// todo use safetransferfrom
		sellToken.transfer(address(tokenExchanger), amountIn);

		uint256 boughtAmount = _purchaseUnderlyingAssets(exactAmountOut, sellToken, swapTarget, tokenOrders);

		_indexToken.mint(msg.sender, boughtAmount);
		// todo: take fee
	}

	/* todo allow to withdraw dusts */
	function _purchaseUnderlyingAssets(uint256 amountOut /* todo: rename */, IERC20 sellToken, address payable swapTarget, Models.TokenOrder[] calldata tokenOrders) private returns (uint256) {
		uint256 minIndexAmountPurchased /* todo: rename */ = type(uint256).max;

     	for (uint256 i = 0; i < tokenOrders.length; i++) {
			uint256 requiredSum = amountOut * composition[i].amount / 1e18;
        	uint256 amountBought = tokenExchanger.executeTrade(sellToken, IERC20(composition[i].token), swapTarget, tokenOrders[i].callData, reserve);
			uint256 indexAmountPurchased /* todo rename */ = (amountBought * 1e18) / composition[i].amount;
			if (indexAmountPurchased < minIndexAmountPurchased)
				minIndexAmountPurchased = indexAmountPurchased;
		}

		/* todo: make slippage dynamic */
		require(minIndexAmountPurchased >= amountOut * 99 / 100, "BOUGHT_TOO_LITTLE");
		return minIndexAmountPurchased;
	}

	function update(address newContract) public override {
		super.update(newContract);
	}
}