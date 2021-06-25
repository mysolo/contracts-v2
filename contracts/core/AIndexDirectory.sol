pragma solidity ^0.8.0;
import "./AIndex.sol";

abstract contract AIndexDirectory {
    AIndex[] _indexes;

    function registerIndex(address indexAddress) public virtual onlyOwner {
        _indexes.push(AIndex(indexAddress));
        //event
    }

    function unregisterIndex(address indexAddress) public virtual onlyOwner {
        for (uint256 i = 0; i < _indexes.length; i++) {
            if (address(_indexes[i]) == indexAddress) {
                _indexes[i] = _indexes[_indexes.length - 1];
                _indexes.pop();
            }
        }
        //event
    }
}
