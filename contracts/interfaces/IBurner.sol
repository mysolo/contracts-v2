// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBurner {
    function burn(address account, uint256 amount) external;
}
