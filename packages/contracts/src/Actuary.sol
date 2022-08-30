// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {InsurancePool} from "./InsurancePool.sol";
import {Adjuster} from "./Adjuster.sol";

contract Actuary {
    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewAdmin(address _previousAdmin, address _newAdmin);
    event NewInsurancePool(address _insurancePool);
    event NewAdjuster(address _adjuster);
    event InsurancePurchaced(uint256 id, Certificates _certificate);
    event InsuranceActivated(uint256 id, Certificates _certificate);
    event InsuranceClaimed(uint256 id, Certificates _certificate);
    event InsuranceExpired(uint256 id, Certificates _certificate);
    event InsuranceCanceled(uint256 id, Certificates _certificate);

    /*///////////////////////////////////////////////////////////////
                            Custom Types
    //////////////////////////////////////////////////////////////*/

    enum Status {
        INACTIVE,
        ACTIVE,
        CLAIMED,
        EXPIRED,
        CANCELED
    }

    struct Certificate {
        address insuree;
        uint256 premium;
        uint256 escrowed;
        mapping(address => uint256) guarantors;
        mapping(address => uint256) guarantorExits;
        uint256 totalExits;
        uint256 startTime;
        uint256 endTime;
    }

    /*///////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev The address of the admin
    address public admin;
    /// @dev The address of the insurance pool
    InsurancePool public pool;
    /// @dev The address of the adjuster
    Adjuster public adjuster;
    /// @dev The payment token
    ERC20 public usd;
    /// @dev The id of the last claim
    uint256 public id;
    /// @dev A mapping of all the certificates
    mapping(uint256 => Certificate) public certificates;

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _admin,
        address _pool,
        address _adjuster,
        address _usd
    ) public {
        admin = _admin;
        pool = InsurancePool(_pool);
        adjuster = Adjuster(_adjuster);
        usd = ERC20(_usd);
        id = 0;
    }

    /*///////////////////////////////////////////////////////////////
                            VIEW ACTIONS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                            MUTABLE ACTIONS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                            ADMIN ACTIONS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/
}
