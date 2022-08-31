// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {InsurancePool} from "./InsurancePool.sol";
import {Adjuster} from "./Adjuster.sol";
import {Certificate} from "./Certificate.sol";
import {Status} from "./lib/State.sol";

// TODO: Split this contract up into escrow and Actuary
contract Actuary is Owned {
    /* ====================================================================== //
                                    ERRORS
    /* ====================================================================== */

    error NotOwner();
    error InsufficentSnapshotBalance();
    error NoEscrowClaim();
    error InsuranceNotClaimable();
    error InsuranceNotExpired();

    /* ====================================================================== //
                                    EVENTS
    /* ====================================================================== */

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
    event LpRequestEscrow(
        address indexed lp,
        uint256 _amountToClaim,
        uint256 _snapshotId
    );
    event LpClaimedEscrow(
        address indexed lp,
        uint256 _amountClaimed,
        uint256 _snapshotId
    );

    /* ====================================================================== //
                                    STORAGE
    /* ====================================================================== */
    address public admin;
    InsurancePool public pool;
    Adjuster public adjuster;
    Certificate public certificate;
    ERC20 public usd;
    mapping(uint256 => mapping(address => uint256)) escorowClaims;
    mapping(uint256 => uint256) totalEscrowedClaims;

    /* ====================================================================== //
                                    CONSTRUCTOR
    /* ====================================================================== */

    constructor(address _admin) Owned(_admin) {}

    function init(
        address _pool,
        address _adjuster,
        address _certificate,
        address _usd
    ) external onlyOwner {
        pool = InsurancePool(_pool);
        adjuster = Adjuster(_adjuster);
        certificate = Certificate(_certificate);
        usd = ERC20(_usd);
    }

    /* ====================================================================== //
                                    VIEW ACTIONS
    /* ====================================================================== */

    function getQuote(uint256 _coverAmount) public pure returns (uint256) {
        // TESTING: 1% of cover amount
        return _coverAmount / 100;
    }

    /* ====================================================================== //
                                    MUTABLE ACTIONS
    /* ====================================================================== */

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

    function cancelInsurance(uint256 _certificateId) external {
        // 1. Check msg.sender is owner
        if (certificate.ownerOf(_certificateId) != msg.sender) {
            revert NotOwner();
        }

        // 3. Repay escrow
        uint256 escrow = certificate.escrowed(_certificateId);
        usd.approve(address(pool), escrow);
        pool.refundEscrow(escrow);

        // 2. Cancel Insurance Certificate
        certificate.setCanceled(_certificateId);

        // 4. Emit the event
        emit InsuranceCanceled(
            _certificateId,
            certificate.getEscrowed(_certificateId)
        );
    }

    function claimInsurance(uint256 _certificateId) external {
        // 1. Check msg.sender is owner
        if (certificate.ownerOf(_certificateId) != msg.sender) {
            revert NotOwner();
        }
        // 2. check insurance is claimable
        if (!adjuster.insuranceClaimable(_certificateId)) {
            revert InsuranceNotClaimable();
        }

        uint256 escrowed = certificate.getEscrowed(_certificateId);

        // 3. Claim escrow
        usd.transfer(address(this), escrowed);

        // 4. Emit the event
        emit InsuranceClaimed(_certificateId, escrowed);
    }

    function expireInsurance(uint256 _certificateId) external {
        uint256 endTime = certificate.endTime(_certificateId);
        if (block.number < endTime) revert InsuranceNotExpired();
        certificate.setExpired(_certificateId);

        uint256 escrowed = certificate.getEscrowed(_certificateId);
        uint256 totalClaims = totalEscrowedClaims[_certificateId];
        uint256 refundable = escrowed - totalClaims;

        usd.approve(address(pool), refundable);
        pool.refundEscrow(refundable);

        emit InsuranceExpired(_certificateId, refundable, totalClaims);
    }

    function lpRequestEscrow(uint256 _amountToClaim, uint256 _snapshotId)
        external
    {
        uint256 balanceAtSnapshot = pool.balanceOfAt(msg.sender, _snapshotId);
        uint256 balanceNow = pool.balanceOf(msg.sender);
        if (_amountToClaim > balanceAtSnapshot - balanceNow) {
            revert InsufficentSnapshotBalance();
        }
        // if so, claim
        escorowClaims[_snapshotId][msg.sender] = _amountToClaim;
        totalEscrowedClaims[_snapshotId] += _amountToClaim;
        emit LpRequestEscrow(msg.sender, _amountToClaim, _snapshotId);
    }

    function lpClaimEscrow(uint256 _snapshotId) external {
        uint256 amountToClaim = escorowClaims[_snapshotId][msg.sender];
        if (amountToClaim == 0) {
            revert NoEscrowClaim();
        }
        if (certificate.status(_snapshotId) != Status.EXPIRED) {
            revert InsuranceNotClaimable();
        }
        // if so, claim
        escorowClaims[_snapshotId][msg.sender] = 0;
        totalEscrowedClaims[_snapshotId] -= amountToClaim;
        usd.transfer(msg.sender, amountToClaim);
        emit LpClaimedEscrow(msg.sender, amountToClaim, _snapshotId);
    }
}
