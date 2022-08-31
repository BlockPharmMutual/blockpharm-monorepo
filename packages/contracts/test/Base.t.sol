// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {InsurancePool} from "../src/InsurancePool.sol";
import {Adjuster} from "../src/Adjuster.sol";
import {Certificate} from "../src/Certificate.sol";
import {Actuary} from "../src/Actuary.sol";
import {MockUSD} from "../src/tokens/MockUSD.sol";

contract BaseTest is Test {
    // People
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address lp1 = makeAddr("lp1");
    address lp2 = makeAddr("lp2");

    // Contracts
    Actuary public actuary;
    Adjuster public adjuster;
    InsurancePool public pool;
    Certificate public certificate;
    MockUSD public usd;

    // Constants
    uint256 public constant HUNDRED_K = 100_000 * 10 * 18;
    address[] to = [alice, bob, lp1, lp2];

    function setUp() public {
        // create contracts
        usd = new MockUSD();
        actuary = new Actuary(address(this));
        adjuster = new Adjuster();
        pool = new InsurancePool(address(this), usd, "PoolOne", "POOL1");
        certificate = new Certificate("Insurance Certificate", "CERT");

        // set up contracts
        actuary.init(
            address(pool),
            address(adjuster),
            address(certificate),
            address(usd)
        );
        pool.init(actuary);
        certificate.init(actuary, pool, adjuster);

        // mint tokens
        usd.mint(to, HUNDRED_K);
    }
}
