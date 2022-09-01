// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {InsurancePool} from "../src/InsurancePool.sol";
import {Adjuster} from "../src/Adjuster.sol";
import {Certificate} from "../src/Certificate.sol";
import {Actuary} from "../src/Actuary.sol";
import {MockUSD} from "../src/tokens/MockUSD.sol";

contract DeployGoerli is Script {
    // Constants
    uint256 public constant HUNDRED_K = 100_000 * 10**18;

    // Contracts
    Actuary public actuary;
    Adjuster public adjuster;
    InsurancePool public pool;
    Certificate public certificate;
    MockUSD public usd;

    function run() public {
        vm.broadcast();

        // create contracts
        usd = new MockUSD();
        actuary = new Actuary(address(this));
        adjuster = new Adjuster();
        pool = new InsurancePool(address(this), usd, "PoolOne", "POOL1");
        certificate = new Certificate("Insurance Certificate", "CERT");

        vm.stopBroadcast();
    }
}
