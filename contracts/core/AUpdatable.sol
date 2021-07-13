//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract AUpdatable is Ownable {
    bool _upToDate;

    event Updated(address newContract);

    constructor() {
        _upToDate = true;
    }

    modifier onlyUpToDate() {
        require(_upToDate, "Updatable: contract not up to date");
        _;
    }

    modifier onlyOutdated() {
        require(!_upToDate, "Updatable: contract not outdated");
        _;
    }

    function update(address newContract) public virtual onlyOwner onlyUpToDate {
        _upToDate = false;
        emit Updated(newContract);
    }
}
