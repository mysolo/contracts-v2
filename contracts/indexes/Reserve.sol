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

    event ManagerAdded(address manager);
    event ManagerRemoved(address manager);

    constructor(address[] memory _managers) {
        addManager(address(this));
        for (uint32 i = 0; i < _managers.length; i++) addManager(_managers[i]);
    }

    function addManager(address manager) public onlyOwner {
        require(!managers[manager], "ALREADY_A_MANAGER");
        managers[manager] = true;
        emit ManagerAdded(manager);
    }

    function removeManager(address manager) external onlyOwner {
        require(managers[manager], "NOT_A_MANAGER");
        managers[manager] = false;
        emit ManagerRemoved(manager);
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

    function update(address newContract) public virtual override {
        addManager(newContract);
        super.update(newContract);
    }
}
