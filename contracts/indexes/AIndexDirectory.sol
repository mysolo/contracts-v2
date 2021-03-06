pragma solidity ^0.8.0;

import "contracts/core/AIndex.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AIndexDirectory is Ownable {
    AIndex[] _indexes;

    event IndexRegistered(address index);
    event IndexUnregistered(address index);

    function registerIndex(address indexAddress) public virtual onlyOwner {
        _indexes.push(AIndex(indexAddress));
        emit IndexRegistered(indexAddress);
    }

    function unregisterIndex(address indexAddress) public virtual onlyOwner {
        for (uint256 i = 0; i < _indexes.length; i++) {
            if (address(_indexes[i]) == indexAddress) {
                _indexes[i] = _indexes[_indexes.length - 1];
                _indexes.pop();
            }
        }
        emit IndexUnregistered(indexAddress);
    }
}
