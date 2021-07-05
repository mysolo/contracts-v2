// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract TokenExchanger is Ownable {
  mapping(address => bool) public indexes;

  function registerIndex(address index) external onlyOwner {
    indexes[index] = true;
  }

  function unregisterIndex(address index) external onlyOwner {
    delete indexes[index];
  }

  modifier onlyIndex {
    require(indexes[msg.sender], "CALLER_NOT_ALLOWED");
    _;
  }

  function transfer(
    IERC20 token,
    uint256 amount,
    address to
  ) public onlyIndex {
    token.transfer(to, amount);
  }

  // todo make it non reentrant
  function executeTrade(
    IERC20 sellToken,
    IERC20 buyToken,
    address swapTarget,
    bytes calldata callData,
    address recipient
  ) external returns (uint256) {
    setMaxAllowance(sellToken, swapTarget);

    uint256 balanceBefore = buyToken.balanceOf(address(this));

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = swapTarget.call(callData);

    uint256 balanceAfter = buyToken.balanceOf(address(this));
    uint256 amountBought = balanceAfter - balanceBefore;

    if (success && amountBought > 0)
      // todo safetransfer
      buyToken.transfer(recipient, amountBought);
    return amountBought;
  }

  function setMaxAllowance(IERC20 token, address spender) internal {
    if (token.allowance(address(this), spender) != type(uint256).max) {
      token.approve(spender, type(uint256).max);
    }
  }

  function _getRevertMsg(bytes memory _returnData)
    internal
    pure
    returns (string memory)
  {
    // If the _res length is less than 68, then the transaction failed silently (without a revert message)
    if (_returnData.length < 68) return "Transaction reverted silently";

    assembly {
      // Slice the sighash.
      _returnData := add(_returnData, 0x04)
    }
    return abi.decode(_returnData, (string)); // All that remains is the revert string
  }

  receive() external payable {}
}
