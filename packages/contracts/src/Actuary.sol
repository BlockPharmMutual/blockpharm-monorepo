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

    error CertificateNotInactive();
    error CertificateActive();
    error CertificateNotExpired();
    error CertificateExpired();
    error CertificateNotClaimed();
    error CertificateClaimed();

    error NotOwner();

    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewAdmin(address _previousAdmin, address _newAdmin);
    event NewInsurancePool(address _insurancePool);
    event NewAdjuster(address _adjuster);
    event InsurancePurchaced(
        uint256 id,
        uint256 premiumPaid,
        uint256 usdEscrowed,
        uint256 startTime,
        uint256 endTime
    );
    event InsuranceActivated(uint256 id, uint256 startTime, uint256 endTime);
    event InsuranceClaimed(uint256 id, uint256 usdClaimed);
    event InsuranceExpired(
        uint256 id,
        uint256 usdEscrowedRefunded,
        uint256 usdClaimableByExits
    );
    event InsuranceCanceled(uint256 id, uint256 EscrowedRefunded);

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

    // TODO: implement hook on Vault & Certificate such that when LP withdraws
    /// @dev
    mapping(uint256 => mapping(address => uint256)) escorowClaims;
    /// @dev total escorow claims for each certificate
    mapping(uint256 => uint256) totalEscrowedClaims;

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

    function getQuote(uint256 _coverAmount) public pure returns (uint256) {
        // TESTING: 1% of cover amount
        return _coverAmount / 100;
    }

    /*///////////////////////////////////////////////////////////////
                            MUTABLE ACTIONS
    //////////////////////////////////////////////////////////////*/

    function purchaseInsurance(
        uint256 _coverAmount,
        uint256 _startTime,
        uint256 _endTime
    ) external {
        // 1. Get the quote
        uint256 quote = getQuote(_coverAmount);

        // 2. Transfer the premium to the pool
        usd.transferFrom(msg.sender, address(this), quote);

        // 3. Create the Insurance Certificate
        uint256 certificateId = certificate.mintTo(
            msg.sender,
            quote,
            _coverAmount,
            _startTime,
            _endTime
        );

        // 4. Set the status of the Insurance Certificate
        certificate.setStatus(certificateId, Certificate.Status.INACTIVE);

        // TODO: in test check snapshotId == certificateId
        pool.snapshot();

        // 5. Withdraw cover amount from the pool as escrow
        pool.escrow(_coverAmount);

        // 6. Emit the event
        emit InsurancePurchaced(
            certificateId,
            quote,
            _coverAmount,
            _startTime,
            _endTime
        );
    }

    // insuree cancels certificate
    function cancelInsurance(uint256 _certificateId) external {
        // 1. Check msg.sender is owner
        if (certificate.ownerOf(_certificateId) != msg.sender) {
            revert NotOwner();
        }

        // 2. Check if the certificate is active
        if (
            certificate.getStatus(_certificateId) != Certificate.Status.INACTIVE
        ) {
            revert CertificateNotInactive();
        }

        // 3. Cancel Insurance Certificate
        certificate.setStatus(_certificateId, Certificate.Status.CANCELED);

        // 4. Repay escrow
        usd.transfer(address(this), certificate.getEscrowed(_certificateId));

        // 5. Emit the event
        emit InsuranceCanceled(
            _certificateId,
            certificate.getEscrowed(_certificateId)
        );
    }

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
