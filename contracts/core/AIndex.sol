//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./AUpdatable.sol";
import "./AIndexToken.sol";

abstract contract AIndex is AUpdatable {
    AIndexToken _indexToken;

    constructor(AIndexToken indexToken) {
        _indexToken = indexToken;
        addContractToTranfer(_indexToken);
    }
}
