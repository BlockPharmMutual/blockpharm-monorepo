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
    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotOwner();
    error InsufficentSnapshotBalance();
    error NoEscrowClaim();
    error InsuranceNotClaimable();

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
    /*///////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    address public admin;
    InsurancePool public pool;
    Adjuster public adjuster;
    Certificate public certificate;

    // TODO: implement hook on Vault & Certificate such that when LP withdraws
    mapping(uint256 => mapping(address => uint256)) escorowClaims;
    mapping(uint256 => uint256) totalEscrowedClaims;

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

    /* ====================================================================== //
                                    INSUREE ACTIONS
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

    // insuree cancels certificate
    // TODO: implement lp withdraw logic
    function cancelInsurance(uint256 _certificateId) external {
        // 1. Check msg.sender is owner
        if (certificate.ownerOf(_certificateId) != msg.sender) {
            revert NotOwner();
        }

        // 2. Cancel Insurance Certificate
        certificate.setCanceled(_certificateId);

        // 3. Repay escrow
        usd.transfer(address(this), certificate.getEscrowed(_certificateId));

        // 4. Emit the event
        emit InsuranceCanceled(
            _certificateId,
            certificate.getEscrowed(_certificateId)
        );
    }

    // insuree claims against certificate
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

    /* ====================================================================== //
                                    LP ACTIONS
    /* ====================================================================== */

    // TODO: Test if this is the correct way to do this.
    // operate on balance and not shares
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

    /*///////////////////////////////////////////////////////////////
                            ADMIN ACTIONS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/
}
