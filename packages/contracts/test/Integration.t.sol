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

    function testDepositLpWithoutInsurance() public {
        vm.startPrank(lp1);
        usd.approve(address(pool), HUNDRED_K);
        pool.deposit(HUNDRED_K, lp1);

        changePrank(lp2);
        usd.approve(address(pool), HUNDRED_K);
        pool.deposit(HUNDRED_K, lp2);

        assertEq(usd.balanceOf(address(pool)), HUNDRED_K * 2);
        assertEq(pool.balanceOf(lp1), HUNDRED_K);
        assertEq(pool.balanceOf(lp2), HUNDRED_K);
        vm.stopPrank();
    }

    function testWithdrawLpWithoutInsurance() public {
        vm.startPrank(lp1);
        usd.approve(address(pool), HUNDRED_K);
        pool.deposit(HUNDRED_K, lp1);

        changePrank(lp2);
        usd.approve(address(pool), HUNDRED_K);
        pool.deposit(HUNDRED_K, lp2);

        assertEq(usd.balanceOf(address(pool)), HUNDRED_K * 2);
        assertEq(pool.balanceOf(lp1), HUNDRED_K);
        assertEq(pool.balanceOf(lp2), HUNDRED_K);

        // withdraw
        changePrank(lp1);
        pool.withdraw(HUNDRED_K, lp1, lp1);
        assertEq(usd.balanceOf(address(lp1)), HUNDRED_K);
        assertEq(pool.balanceOf(lp1), 0);
        assertEq(usd.balanceOf(address(pool)), HUNDRED_K);
        vm.stopPrank();
    }
}
