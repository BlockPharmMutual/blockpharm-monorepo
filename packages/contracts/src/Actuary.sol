// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {InsurancePool} from "./InsurancePool.sol";
import {Adjuster} from "./Adjuster.sol";
import {Certificate} from "./Certificate.sol";

contract Actuary is Owned {
    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error CertificateInactive();
    error CertificateActive();
    error CertificateNotExpired();
    error CertificateExpired();
    error CertificateNotClaimed();
    error CertificateClaimed();

    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewAdmin(address _previousAdmin, address _newAdmin);
    event NewInsurancePool(address _insurancePool);
    event NewAdjuster(address _adjuster);
    event InsurancePurchaced(uint256 id);
    event InsuranceActivated(uint256 id);
    event InsuranceClaimed(uint256 id);
    event InsuranceExpired(uint256 id);
    event InsuranceCanceled(uint256 id);

    /*///////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev The address of the admin
    address public admin;
    /// @dev The insurance pool
    InsurancePool public pool;
    /// @dev The adjuster
    Adjuster public adjuster;
    /// @dev The certificate
    Certificate public certificate;
    /// @dev The payment token
    ERC20 public usd;

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _admin,
        address _pool,
        address _adjuster,
        address _certificate,
        address _usd
    ) Owned(_admin) {
        admin = _admin;
        pool = InsurancePool(_pool);
        adjuster = Adjuster(_adjuster);
        certificate = Certificate(_certificate);
        usd = ERC20(_usd);
    }

    /*///////////////////////////////////////////////////////////////
                            VIEW ACTIONS
    //////////////////////////////////////////////////////////////*/

    function getQuote(uint256 _coverAmount) public view returns (uint256) {
        // TESTING: 1% of cover amount
        return _coverAmount / 100;
    }

    /*///////////////////////////////////////////////////////////////
                            MUTABLE ACTIONS
    //////////////////////////////////////////////////////////////*/

    function purchaseInsurance(
        address _insuree,
        uint256 _coverAmount,
        uint256 _startTime,
        uint256 _endTime
    ) external {
        // Get the quote
        uint256 quote = getQuote(_coverAmount);

        // Transfer the premium to the pool
        usd.transferFrom(msg.sender, address(this), quote);

        // withdraw cover amount from the pool as escrow
        pool.escrow(_coverAmount);

        // Create the certificate
        uint256 certificateId = certificate.mintTo(
            msg.sender,
            quote,
            _coverAmount,
            _startTime,
            _endTime
        );

        // TODO: in test check snapshotId == certificateId
        uint256 snapshotId = pool.snapshot();

        // Emit the event
        emit InsurancePurchaced(certificateId);
    }

    // insuree cancels certificate

    // insuree claims against certificate

    // guarantor requests exit

    // guarantor exits

    //

    /*///////////////////////////////////////////////////////////////
                            ADMIN ACTIONS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/
}
