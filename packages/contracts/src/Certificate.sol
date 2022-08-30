// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import {Actuary} from "./Actuary.sol";
import {InsurancePool} from "./InsurancePool.sol";
import {Adjuster} from "./Adjuster.sol";

contract Certificate is ERC721 {
    /* ====================================================================== //
                                    ERRORS
    // ====================================================================== */

    error OnlyActuary();

    /* ====================================================================== //
                                    STORAGE
    // ====================================================================== */

    enum Status {
        INACTIVE,
        ACTIVE,
        CLAIMED,
        EXPIRED,
        CANCELED
    }

    Actuary public actuary;
    InsurancePool public pool;
    Adjuster public adjuster;

    uint256 public currentTokenId;
    mapping(uint256 => address) insuree;
    mapping(uint256 => uint256) premium;
    mapping(uint256 => uint256) escrowed;
    mapping(uint256 => uint256) totalExits;
    mapping(uint256 => uint256) startTime;
    mapping(uint256 => uint256) endTime;
    mapping(uint256 => Status) status;

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
        status[newItemId] = Status.INACTIVE;
        totalExits[newItemId] = 0;

        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function setStatus(uint256 _tokenId, Status _status) external {
        if (msg.sender != address(actuary)) revert OnlyActuary();
        // TODO: perform checks
        status[_tokenId] = _status;
    }
}
