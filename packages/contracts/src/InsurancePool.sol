// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
// import {IERC4626} from "./interfaces/IERC4626.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "./tokens/ERC20.sol";
import {Actuary} from "./Actuary.sol";
import {VaultSnapshotable} from "./vault/VaultSnapshotable.sol";

// snapshot is used to create a snapshot of the balances when a claim is made
// since snapshots should only be created when a certificate is minted the tokenId
// of the certificate should be used as the snapshot id
contract InsurancePool is VaultSnapshotable, Owned {
    /* ====================================================================== //
                                    ERRORS
    // ====================================================================== */

    error OnlyActuary();

    /* ====================================================================== //
                                    EVENTS
    // ====================================================================== */

    /* ====================================================================== //
                                    STORAGE
    // ====================================================================== */

    Actuary public actuary;

    /* ====================================================================== //
                                    CONSTRUCTOR
    // ====================================================================== */

    constructor(
        address _owner,
        Actuary _actuary,
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) Owned(_owner) VaultSnapshotable(_asset, _name, _symbol) {
        actuary = _actuary;
    }

    /* ====================================================================== //
                                    PROTOCOL ACTIONS
    /* ====================================================================== */

    function escrow(uint256 _amount) external {
        if (msg.sender != address(actuary)) revert OnlyActuary();
        asset.transferFrom(msg.sender, address(this), _amount);
    }

    function snapshot() external returns (uint256) {
        if (msg.sender != address(actuary)) revert OnlyActuary();
        return _snapshot();
    }

    /* ====================================================================== //
                                    INTERNAL HOOKS
    /* ====================================================================== */

    function afterWithdraw() internal {}
}
