// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Base.t.sol";

contract IntegrationTest is BaseTest {
    function testSetup() public {
        assertEq(usd.balanceOf(alice), HUNDRED_K);
        assertEq(usd.balanceOf(bob), HUNDRED_K);
        assertEq(usd.balanceOf(lp1), HUNDRED_K);
        assertEq(usd.balanceOf(lp2), HUNDRED_K);
    }
}
