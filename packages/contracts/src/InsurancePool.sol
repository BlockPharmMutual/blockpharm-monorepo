// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract InsurancePool is ERC20 {
    function escrow(uint256 _amount);
}
