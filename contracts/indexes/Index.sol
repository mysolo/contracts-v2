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

    receive() external payable {}

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

        bool isSellTokenETH = address(sellToken) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        if (isSellTokenETH)
		    sellToken = IERC20(address(_WETH));

        uint256 exchangerBalanceBefore = sellToken.balanceOf(address(tokenExchanger));

		if (!isSellTokenETH) {
			// todo use safe transferfrom
			sellToken.transferFrom(msg.sender, address(tokenExchanger), amountIn);
		} else {
  	       _WETH.deposit{value: msg.value}();
           _WETH.transfer(address(tokenExchanger), msg.value); 
        }

        // todo make updatable, possibly add VIP tiers
        uint256 fees = amountIn / 100;
        uint256 amountInWithFees = amountIn + fees;

        uint256 boughtAmount = _purchaseUnderlyingAssets(
            minAmountOut,
            sellToken,
            swapTarget,
            tokenOrders
        );

        // refund the user for the sell token that hasn't been used in trades
        uint256 exchangerBalanceAfter = sellToken.balanceOf(address(tokenExchanger));
        uint256 refundAmount = exchangerBalanceAfter - exchangerBalanceBefore;
        payUser(sellToken, refundAmount, isSellTokenETH);

		_indexToken.mint(msg.sender, boughtAmount);
		// todo: take fee

        console.log(sellToken.balanceOf(address(tokenExchanger)));
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
		_indexToken.burn(msg.sender, amountOut);

        bool isBuyTokenETH = address(buyToken) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
		if (isBuyTokenETH)
			buyToken = IERC20(address(_WETH));

		uint256 saleAmount = _sellUnderlyingAssets(amountOut, buyToken, swapTarget, tokenOrders);
        uint256 refund = 0;
        payUser(buyToken, saleAmount + refund, isBuyTokenETH);
	}

	function _sellUnderlyingAssets(uint256 amountOut, IERC20 buyToken, address payable swapTarget, TokenOrder[] calldata tokenOrders) private returns (uint256) {
        uint256 totalSaleAmount = 0;

        for (uint256 i = 0; i < tokenOrders.length; i++) {
            IERC20 sellToken = IERC20(composition[i].token);

            // todo use reserve
            sellToken.transfer(
                address(tokenExchanger),
                (amountOut * composition[i].amount) / 1e18 /* dynamic decimals? */
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

    // could happen in exchanger?
    function payUser(IERC20 token, uint256 amount, bool unwrapEther) private {
        if (unwrapEther) {
          tokenExchanger.transfer(IERC20(address(_WETH)), amount, address(this));
  	      _WETH.withdraw(amount);
          (bool success, ) = msg.sender.call{ value: amount }("");
          require(success, "ETH_TRANSFER_ERROR");
        } else token.transfer(msg.sender, amount);
    }

	function update(address newContract) public override {
		super.update(newContract);
	}
}
