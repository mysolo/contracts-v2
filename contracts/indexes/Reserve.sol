// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/core/AUpdatable.sol";
import "./Index.sol";

/**
 * This contract holds all index underlying funds
 */
contract Reserve is AUpdatable {
  mapping(address => bool) managers;

  constructor(address[] memory _managers) {
    for (uint32 i = 0; i < _managers.length; i++) addManager(_managers[i]);
  }

  function addManager(address manager) public onlyOwner {
    require(!managers[manager], "ALREADY_A_MANAGER");
    managers[manager] = true;
  }

  function removeManager(address manager) external onlyOwner {
    require(managers[manager], "NOT_A_MANAGER");
    managers[manager] = false;
  }

  modifier onlyManager {
    require(managers[msg.sender], "FORBIDDEN");
    _;
  }

  function transfer(
    IERC20 token,
    uint256 amount,
    address to
  ) public onlyManager returns (bool) {
    return token.transfer(to, amount);
  }

  function withdraw(IERC20 token, uint256 amount)
    external
    onlyManager
    returns (bool)
  {
    return transfer(token, amount, msg.sender);
  }

  // could be a useful function when tokens will be stored in vaults in a new reserve contract
  function hasToken(IERC20 token) external view returns (bool) {
    return token.balanceOf(address(this)) > 0;
  }
}
