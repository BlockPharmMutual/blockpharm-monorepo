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

    // Logs
    event log_named_address(string key, address val);

    // Contracts
    Actuary public actuary;
    Adjuster public adjuster;
    InsurancePool public pool;
    Certificate public certificate;
    MockUSD public usd;

    function run() public {
        vm.startBroadcast();

        // create contracts
        usd = new MockUSD();
        actuary = new Actuary(address(this));
        adjuster = new Adjuster();
        pool = new InsurancePool(address(this), usd, "PoolOne", "POOL1");
        certificate = new Certificate("Insurance Certificate", "CERT");

        emit log_named_address("usd", address(usd));
        emit log_named_address("actuary", address(actuary));
        emit log_named_address("adjuster", address(adjuster));
        emit log_named_address("pool", address(pool));
        emit log_named_address("certificate", address(certificate));

        // set up contracts
        actuary.init(
            address(pool),
            address(adjuster),
            address(certificate),
            address(usd)
        );
        pool.init(actuary);
        certificate.init(actuary, pool, adjuster);

        vm.stopBroadcast();
    }
}
