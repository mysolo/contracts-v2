import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/team/TokenSharing.sol";

abstract contract FeesController is Ownable {
    IERC20[] _tokens;
    TokenSharing _tokenSharing;

    constructor(address tokenSharing) {
        _tokenSharing = TokenSharing(tokenSharing);
    }

    function addToken(address token) external virtual onlyOwner {
        _tokens.push(IERC20(token));
    }

    function removeToken(address token) external virtual onlyOwner {
        for (uint256 i = 0; i < _tokens.length - 1; i++) {
            if (address(_tokens[i]) == token) {
                _tokens[i] = _tokens[_tokens.length - 1];
                delete _tokens[_tokens.length - 1];
                return;
            }
        }
    }

    function distribute() external virtual {
        // swap all tokens into bnb (pair bnb/ token)
        // give X% to the caller
        // buy back lev (bnb/lev)
        // give X% to the teamsharing contract
    }

    function estimatedReward() external view virtual {
        // return estimated rewards if the user call distribute
    }
}
