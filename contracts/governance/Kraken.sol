pragma solidity ^0.8.0;

import "./TimelockController.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/core/AUpdatable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Kraken is TimelockController {
    mapping(bytes32 => mapping(address => int256)) private _votes;
    mapping(bytes32 => int256) private _results;
    ERC20[] _votingTokens;
    uint16[] _votingTokensWeight;

    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address[] memory votingTokens,
        uint16[] memory votingTokensWeight
    ) TimelockController(minDelay, proposers, executors) {
        for (uint16 i = 0; i < votingTokens.length; i++) {
            _votingTokens.push(ERC20(votingTokens[i]));
        }
        _votingTokensWeight = votingTokensWeight;
    }

    modifier onlyOpenedOperation(bytes32 id) {
        uint256 timestamp = getTimestamp(id);
        require(isOpened(id), "Kraken: outside of voting timeframe");
        _;
    }

    modifier onlyExecutableAction(bytes32 id) {
        require(
            isOperationReady(id) && isFavorable(id),
            "Kraken: Invalid operation to execute"
        );
        _;
    }

    function isOpened(bytes32 id) public view returns (bool) {
        uint256 timestamp = getTimestamp(id);
        return isOperationPending(id) && block.timestamp < timestamp;
    }

    function isFavorable(bytes32 id) public view returns (bool) {
        return _results[id] > 0;
    }

    function vote(bytes32 id, bool favorable)
        public
        virtual
        onlyOpenedOperation(id)
    {
        int256 currentVote = _votes[id][msg.sender];
        _results[id] -= currentVote;
        int256 voteWeight = 0;
        for (uint16 i = 0; i < _votingTokens.length; i++) {
            voteWeight = (int256)(
                _votingTokens[i].balanceOf(msg.sender) * _votingTokensWeight[i]
            ); // what if uint is > int please check !important
        }
        voteWeight = favorable ? voteWeight : voteWeight * -1;
        _votes[id][msg.sender] = voteWeight;
        _results[id] += voteWeight;
    }

    function resetvote(bytes32 id) public virtual onlyOpenedOperation(id) {
        int256 currentVote = _votes[id][msg.sender];
        _results[id] -= currentVote;
        _votes[id][msg.sender] = 0;
    }

    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    )
        public
        payable
        virtual
        override
        onlyExecutableAction(
            hashOperation(target, value, data, predecessor, salt)
        )
    {
        super.execute(target, value, data, predecessor, salt);
    }

    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    )
        public
        payable
        virtual
        override
        onlyExecutableAction(
            hashOperationBatch(targets, values, datas, predecessor, salt)
        )
    {
        super.executeBatch(targets, values, datas, predecessor, salt);
    }
}
