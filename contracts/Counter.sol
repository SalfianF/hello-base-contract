// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Counter {
    uint256 private _count;

    event CountIncremented(uint256 newCount);
    event CountDecremented(uint256 newCount);

    function increment() external {
        _count++;
        emit CountIncremented(_count);
    }

    function decrement() external {
        require(_count > 0, "Counter: cannot go below zero");
        _count--;
        emit CountDecremented(_count);
    }

    function count() external view returns (uint256) {
        return _count;
    }

    function reset() external {
        _count = 0;
    }
}