// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./Index.sol";
import "../models/IndexComposition.sol";
import "hardhat/console.sol";

contract IndexPriceEstimator {
  IUniswapV2Router02 public router;
  address public BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
  address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

  constructor(IUniswapV2Router02 _uniswapRouter) {
    router = _uniswapRouter;
  }

  // get a quote in USD to purchase an index
  function getIndexQuote(Index index, uint256 amount)
    external
    view
    returns (uint256)
  {
    IndexComposition[] memory composition = index.getComposition();
    uint256 totalPrice = 0;
    address[] memory fullRoute = new address[](3);
    fullRoute[0] = BUSD;
    fullRoute[1] = WBNB;
    address[] memory busdBnbRoute = new address[](2);
    busdBnbRoute[0] = BUSD;
    busdBnbRoute[1] = WBNB;

    for (uint32 i = 0; i < composition.length; i++) {
      address token = composition[i].token;
      fullRoute[2] = token;

      if (token == BUSD) {
        totalPrice += composition[i].amount * amount;
        continue;
      }

      uint256[] memory amounts = router.getAmountsIn(
        (composition[i].amount * amount) / 1e18,
        token == WBNB ? busdBnbRoute : fullRoute
      );
      totalPrice += amounts[0];
    }

    return totalPrice;
  }
}
