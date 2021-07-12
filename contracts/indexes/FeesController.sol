// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "contracts/team/TokenSharing.sol";
import "contracts/tokens/LEVToken.sol";

import "hardhat/console.sol";

contract FeesController is Ownable {
  TokenSharing _tokenSharing;
  IUniswapV2Router02 _router;
  IERC20 _rewardToken;
  uint16 _buyBackPerThousand;
  LEVToken _LEV;

  event RewardTokenChanged(address rewardToken);
  event BuybackChanged(address buybackPerThousand);
  event Triggered(address token, uint256 amount);
  event LevBoughtBack(uint256 amount);

  constructor(
    uint16 buyBackPerThousand,
    address tokenSharing,
    IERC20 rewardToken,
    LEVToken LEV,
    IUniswapV2Router02 router
  ) {
    _tokenSharing = TokenSharing(tokenSharing);
    _router = router;
    _LEV = LEV;
    changeBuyback(buyBackPerThousand);
    changeRewardToken(rewardToken);
  }

  function changeRewardToken(IERC20 rewardToken) public virtual onlyOwner {
    require(
      address(rewardToken) != address(_LEV),
      "FeesController : Reward token cannot be LEV"
    );
    _rewardToken = rewardToken;
  }

  function changeBuyback(uint16 buyBackPerThousand) public virtual onlyOwner {
    require(
      buyBackPerThousand <= 1000,
      "FeesController : buyback must be <= 100%"
    );
    _buyBackPerThousand = buyBackPerThousand;
  }

  function pay(IERC20 originToken, uint256 amount) external virtual {
    originToken.transferFrom(msg.sender, address(this), amount);

    if (address(originToken) != address(_rewardToken))
      sellToken(
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
    sellToken(
      address(_rewardToken),
      address(_LEV),
      address(this),
      buybackAmount,
      _router
    );
    _LEV.burn(_LEV.balanceOf(address(this)));
    emit Triggered(address(originToken), amount);
  }

  function sellToken(
    address tokenToSell,
    address paymentToken,
    address account,
    uint256 amountIn,
    IUniswapV2Router02 pancakeRouter
  ) internal returns (uint256, uint256) {
    IERC20(tokenToSell).approve(address(pancakeRouter), amountIn);
    address[] memory path = new address[](2);
    path[0] = tokenToSell;
    path[1] = paymentToken;
    uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(
      amountIn,
      0,
      path,
      account,
      block.timestamp + 60
    );
    emit LevBoughtBack(amounts[1]);
    return (amounts[1], amounts[0]);
  }
}
