// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import {Actuary} from "./Actuary.sol";
import {InsurancePool} from "./InsurancePool.sol";
import {Adjuster} from "./Adjuster.sol";

import {Status} from "./lib/State.sol";

contract Certificate is ERC721 {
    /* ====================================================================== //
                                    ERRORS
    // ====================================================================== */

    error OnlyActuary();
    error CertificateActive();
    error CertificateNotExpired();
    error CertificateExpired();
    error CertificateNotClaimed();
    error CertificateClaimed();
    error CertificateCanceled();
    error StartTimeInFuture();

    /* ====================================================================== //
                                    STORAGE
    // ====================================================================== */

    Actuary public actuary;
    InsurancePool public pool;
    Adjuster public adjuster;

    uint256 public currentTokenId;
    mapping(uint256 => address) public insuree;
    mapping(uint256 => uint256) public premium;
    mapping(uint256 => uint256) public escrowed;
    mapping(uint256 => uint256) public startTime;
    mapping(uint256 => uint256) public endTime;
    mapping(uint256 => Status) public status;

    /* ====================================================================== //
                                    CONSTRUCTOR
    // ====================================================================== */

    constructor(
        string memory _name,
        string memory _symbol,
        Actuary _actuary,
        InsurancePool _insurancePool,
        Adjuster _adjuster
    ) ERC721(_name, _symbol) {
        actuary = _actuary;
        pool = _insurancePool;
        adjuster = _adjuster;
    }

    /* ====================================================================== //
                                    VIEW FUNCTIONS
    // ====================================================================== */

    function getStatus(uint256 _tokenId) public view returns (Status) {
        return status[_tokenId];
    }

    function getEscrowed(uint256 _tokenId) public view returns (uint256) {
        return escrowed[_tokenId];
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return Strings.toString(id);
    }

    /* ====================================================================== //
                                    PROTOCOL ACTIONS
    /* ====================================================================== */

    function mintTo(
        address recipient,
        uint256 _premium,
        uint256 _escrowed,
        uint256 _startTime,
        uint256 _endTime
    ) external payable returns (uint256) {
        if (msg.sender != address(actuary)) revert OnlyActuary();

        uint256 newItemId = ++currentTokenId;
        insuree[newItemId] = recipient;
        premium[newItemId] = _premium;
        escrowed[newItemId] = _escrowed;
        startTime[newItemId] = _startTime;
        endTime[newItemId] = _endTime;
        status[newItemId] = Status.ACTIVE;

        _safeMint(recipient, newItemId);
        setActive(newItemId);
        return newItemId;
    }

    function setActive(uint256 _tokenId) internal {
        if (msg.sender != address(actuary)) revert OnlyActuary();
        Status _status = getStatus(_tokenId);
        if (_status == Status.CLAIMED) revert CertificateClaimed();
        if (_status == Status.EXPIRED) revert CertificateExpired();
        if (block.timestamp > startTime[_tokenId]) revert StartTimeInFuture();
        status[_tokenId] = Status.ACTIVE;
    }

    function setClaimed(uint256 _tokenId) external {
        if (msg.sender != address(actuary)) revert OnlyActuary();
        Status _status = getStatus(_tokenId);
        if (_status == Status.EXPIRED) revert CertificateExpired();
        if (_status == Status.CANCELED) revert CertificateCanceled();
        status[_tokenId] = Status.CLAIMED;
    }

    function setExpired(uint256 _tokenId) external {
        if (msg.sender != address(actuary)) revert OnlyActuary();
        Status _status = getStatus(_tokenId);
        if (_status == Status.CLAIMED) revert CertificateClaimed();
        if (_status == Status.CANCELED) revert CertificateCanceled();
        if (block.timestamp < endTime[_tokenId]) revert CertificateNotExpired();
        status[_tokenId] = Status.EXPIRED;
    }

    function setCanceled(uint256 _tokenId) external {
        if (msg.sender != address(actuary)) revert OnlyActuary();
        Status _status = getStatus(_tokenId);
        if (_status == Status.CLAIMED) revert CertificateClaimed();
        if (_status == Status.EXPIRED) revert CertificateExpired();
        if (block.timestamp > startTime[_tokenId]) revert CertificateActive();
        status[_tokenId] = Status.CANCELED;
    }
}
