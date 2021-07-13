// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./Index.sol";
import "../models/IndexComposition.sol";

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
    address[] memory route = new address[](3);
    route[0] = BUSD;
    route[1] = WBNB;

    for (uint32 i = 0; i < composition.length; i++) {
      route[2] = composition[i].token;
      uint256[] memory amounts = router.getAmountsIn(
        (composition[i].amount * amount) / 1e18,
        route
      );
      totalPrice += amounts[0];
    }

    return totalPrice;
  }
}
