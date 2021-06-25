//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract AUpdatable is Ownable {
    bool _upToDate;
    Ownable[] _contractsToTransfer;
    ERC20[] _tokenToTransfer;

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

    function addContractToTranfer(Ownable contractToTranfer) public onlyOwner {
        _contractsToTransfer.push(contractToTranfer);
    }

    function cleanContractToTranfer() public onlyOwner {
        delete _contractsToTransfer;
    }

    function addTokenToTranfert(ERC20 tokenToTranfer) public onlyOwner {
        _tokenToTransfer.push(tokenToTranfer);
    }

    function cleanTokenToTranfert() public onlyOwner {
        delete _tokenToTransfer;
    }

    function update(address newContract) public virtual onlyOwner {
        for (uint256 i = 0; i < _contractsToTransfer.length; i++) {
            _contractsToTransfer[i].transferOwnership(newContract);
        }
        for (uint256 i = 0; i < _tokenToTransfer.length; i++) {
            ERC20 token = _tokenToTransfer[i];
            token.transfer(newContract, token.balanceOf(address(this)));
        }
        _upToDate = false;
        //event
    }
}
