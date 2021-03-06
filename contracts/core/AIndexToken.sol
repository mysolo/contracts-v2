// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "contracts/interfaces/IMinter.sol";
import "contracts/interfaces/IBurner.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract AIndexToken is ERC20, IMinter, IBurner, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address receiver, uint256 amount)
        external
        override
        onlyOwner
    {
        _mint(receiver, amount);
    }

    function burn(address account, uint256 amount) external override onlyOwner {
        _burn(account, amount);
    }
}
