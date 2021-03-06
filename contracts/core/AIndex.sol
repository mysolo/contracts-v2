//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./AUpdatable.sol";
import "./AIndexToken.sol";

abstract contract AIndex is AUpdatable {
    AIndexToken public _indexToken;

    constructor(AIndexToken indexToken) {
        _indexToken = indexToken;
    }

    function update(address newContract) public virtual override {
        _indexToken.transferOwnership(newContract);
        super.update(newContract);
    }
}
