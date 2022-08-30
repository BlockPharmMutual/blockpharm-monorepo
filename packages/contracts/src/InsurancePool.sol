// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
// import {IERC4626} from "./interfaces/IERC4626.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Actuary} from "./Actuary.sol";
import {ERC20Snapshot} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Snapshot.sol";

// snapshot is used to create a snapshot of the balances when a claim is made
// since snapshots should only be created when a certificate is minted the tokenId
// of the certificate should be used as the snapshot id
contract InsurancePool is ERC20, ERC20Snapshot, Owned {
    /* ====================================================================== //
                                    ERRORS
    // ====================================================================== */

    error OnlyActuary();

    /* ====================================================================== //
                                    EVENTS
    // ====================================================================== */

    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /* ====================================================================== //
                                    STORAGE
    // ====================================================================== */

    Actuary public actuary;
    address public asset;

    /* ====================================================================== //
                                    CONSTRUCTOR
    // ====================================================================== */

    constructor(
        address _owner,
        Actuary _actuary,
        address _asset,
        string memory _name,
        string memory _symbol
    ) Owned(_owner) ERC20(_name, _symbol, ERC20(_asset).decimals()) {
        actuary = _actuary;
        asset = _asset;
    }

    /* ====================================================================== //
                                    VIEW ACTIONS
    /* ====================================================================== */

    function totalAssets() public view returns (uint256) {
        return ERC20(asset).balanceOf(address(this));
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return (shares * totalAssets()) / totalSupply();
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        if (totalAssets() == 0 || totalSupply() == 0) return assets;
        return (assets * totalSupply()) / totalAssets();
    }

    function previewDeposit(uint256 assets) external view returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) external view returns (uint256) {
        uint256 assets = convertToAssets(shares);
        if (assets == 0 && totalAssets() == 0) return shares;
        return assets;
    }

    function previewWithdraw(uint256 assets) external view returns (uint256) {
        uint256 shares = convertToShares(assets);
        if (totalSupply() == 0) return 0;
        return shares;
    }

    function previewRedeem(uint256 shares) external view returns (uint256) {
        return convertToAssets(shares);
    }

    /* ====================================================================== //
                                    PROTOCOL ACTIONS
    /* ====================================================================== */

    function escrow(uint256 _amount) external {
        if (msg.sender != address(actuary)) revert OnlyActuary();
        ERC20(asset).transferFrom(msg.sender, address(this), _amount);
    }

    function snapshot() external returns (uint256) {
        // only the actuary can call this function
        return _snapshot();
    }

    /* ====================================================================== //
                                    USER ACTIONS
    /* ====================================================================== */

    function deposit(uint256 assets, address receiver)
        public
        returns (uint256)
    {
        uint256 shares = convertToShares(assets);
        ERC20(asset).transferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);

        return shares;
    }

    function deposit(uint256 assets) external returns (uint256) {
        return deposit(assets, msg.sender);
    }

    function mint(uint256 shares, address receiver) public returns (uint256) {
        uint256 assets = convertToAssets(shares);

        if (totalAssets() == 0) assets = shares;

        ERC20(asset).transferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);

        return assets;
    }

    function mint(uint256 shares) external returns (uint256) {
        return mint(shares, msg.sender);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public returns (uint256) {
        uint256 shares = convertToShares(assets);

        if (owner != msg.sender) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);

        ERC20(asset).transfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }

    function withdraw(uint256 assets, address receiver)
        external
        returns (uint256)
    {
        return withdraw(assets, receiver, msg.sender);
    }

    function withdraw(uint256 assets) external returns (uint256) {
        return withdraw(assets, msg.sender, msg.sender);
    }
}
