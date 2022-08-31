// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "./ERC20.sol";

contract MockUSD is ERC20 {
    constructor() ERC20("USD", "USD") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function mint(address[] memory to, uint256 amount) public {
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], amount);
        }
    }
}
