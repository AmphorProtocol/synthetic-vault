//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {
    Ownable,
    Ownable2Step
} from "@openzeppelin-v4.9.3/contracts/access/Ownable2Step.sol";
import {
    ERC20,
    IERC20,
    IERC20Metadata
} from "@openzeppelin-v4.9.3/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin-v4.9.3/contracts/utils/math/Math.sol";
import {IERC4626} from "@openzeppelin-v4.9.3/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from
    "@openzeppelin-v4.9.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "@openzeppelin-v4.9.3/contracts/security/Pausable.sol";

/*
 _______  _______  _______           _______  _______
(  ___  )(       )(  ____ )|\     /|(  ___  )(  ____ )
| (   ) || () () || (    )|| )   ( || (   ) || (    )|
| (___) || || || || (____)|| (___) || |   | || (____)|
|  ___  || |(_)| ||  _____)|  ___  || |   | ||     __)
| (   ) || |   | || (      | (   ) || |   | || (\ (
| )   ( || )   ( || )      | )   ( || (___) || ) \ \__
|/     \||/     \||/       |/     \|(_______)|/   \__/
 _______           _       _________          _______ __________________ _______
(  ____ \|\     /|( (    /|\__   __/|\     /|(  ____ \\__   __/\__   __/(  ____ \
| (    \/( \   / )|  \  ( |   ) (   | )   ( || (    \/   ) (      ) (   | (    \/
| (_____  \ (_) / |   \ | |   | |   | (___) || (__       | |      | |   | |
(_____  )  \   /  | (\ \) |   | |   |  ___  ||  __)      | |      | |   | |
      ) |   ) (   | | \   |   | |   | (   ) || (         | |      | |   | |
/\____) |   | |   | )  \  |   | |   | )   ( || (____/\   | |   ___) (___| (____/\
\_______)   \_/   |/    )_)   )_(   |/     \|(_______/   )_(   \_______/(_______/
*/

contract AmphorSyntheticVault is IERC4626, ERC20, Ownable2Step, Pausable {
    /*
     ######
      LIBS
     ######
    */

    /**
     * @dev The `Math` lib is only used for `mulDiv` operations.
     */
    using Math for uint256;

    /**
     * @dev The `SafeERC20` lib is only used for `safeTransfer` and
     * `safeTransferFrom` operations.
     */
    using SafeERC20 for IERC20;

    /*
     #####################################
      GENERAL ERC-4626 RELATED ATTRIBUTES
     #####################################
    */

    /**
     * @dev The decimals amount of the share token.
     */
    uint8 private immutable _decimalsShares;

    /**
     * @dev The underlying asset of the vault.
     */
    IERC20 internal immutable _asset;

    /**
     * @dev The decimals offset of the shares token. This is to protect against
     * inflation attacks.
     * https://blog.openzeppelin.com/a-novel-defense-against-erc4626-inflation-attacks
     * @return Amount of decimals offset of the shares.
     */
    uint8 public immutable decimalsOffset;

    /*
     #####################################
      AMPHOR SYNTHETIC RELATED ATTRIBUTES
     #####################################
    */

    /**
     * @dev The total underlying assets amount just before the lock period.
     * @return Amount of the total underlying assets just before the last vault
     * locking.
     */
    uint256 public lastSavedBalance;

    /**
     * @dev The perf fees applied on the positive yield.
     * @return Amount of the perf fees applied on the positive yield.
     */
    uint16 public feesInBps;

    /**
     * @dev The locking status of the vault.
     * @return `true` if the vault is open for deposits, `false` otherwise.
     */
    bool public vaultIsOpen;

    /*
     ########
      EVENTS
     ########
    */

    /**
     * @dev Emitted when an epoch starts.
     * @param timestamp The block timestamp of the epoch start.
     * @param lastSavedBalance The `lastSavedBalance` when the vault start.
     * @param totalShares The total amount of shares when the vault start.
     */
    event EpochStart(
        uint256 indexed timestamp, uint256 lastSavedBalance, uint256 totalShares
    );

    /**
     * @dev Emitted when an epoch ends.
     * @param timestamp The block timestamp of the epoch end.
     * @param lastSavedBalance The `lastSavedBalance` when the vault end.
     * @param returnedAssets The total amount of underlying assets returned to
     * the vault before collecting fees.
     * @param fees The amount of fees collected.
     * @param totalShares The total amount of shares when the vault end.
     */
    event EpochEnd(
        uint256 indexed timestamp,
        uint256 lastSavedBalance,
        uint256 returnedAssets,
        uint256 fees,
        uint256 totalShares
    );

    /**
     * @dev Emitted when fees are changed.
     * @param oldFees The old fees.
     * @param newFees The new fees.
     */
    event FeesChanged(uint16 oldFees, uint16 newFees);

    /*
     ########
      ERRORS
     ########
    */

    /**
     * @dev The vault is in locked state. Emitted if the tx cannot happen in
     * this state.
     */
    error VaultIsLocked();

    /**
     * @dev The vault is in open state. Emitted if the tx cannot happen in this
     * state.
     */
    error VaultIsOpen();

    /**
     * @dev The rules doesn't allow the perf fees to be higher than 30.00%.
     */
    error FeesTooHigh();

    /**
     * @dev Claiming the underlying assets is not allowed.
     */
    error CannotClaimAsset();

    /**
     * @dev Attempted to deposit more underlying assets than the max amount for
     * `receiver`.
     */
    error ERC4626ExceededMaxDeposit(
        address receiver, uint256 assets, uint256 max
    );

    /**
     * @dev Attempted to mint more shares than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxMint(address receiver, uint256 shares, uint256 max);

    /**
     * @dev Attempted to withdraw more underlying assets than the max amount for
     * `receiver`.
     */
    error ERC4626ExceededMaxWithdraw(address owner, uint256 assets, uint256 max);

    /**
     * @dev Attempted to redeem more shares than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxRedeem(address owner, uint256 shares, uint256 max);

    /**
     * @dev Attempted to mint less shares than the min amount for `receiver`.
     * This error is only thrown when the `depositMinShares` function is used.
     * @notice The `depositMinShares` function is used to deposit underlying
     * assets into the vault. It also checks that the amount of shares minted is
     * greater or equal to the specified minimum amount.
     * @param owner The address of the owner.
     * @param shares The shares amount to be converted into underlying assets.
     * @param minShares The minimum amount of shares to be minted.
     */
    error ERC4626NotEnoughSharesMinted(
        address owner, uint256 shares, uint256 minShares
    );

    /**
     * @dev Attempted to withdraw more underlying assets than the max amount for
     * `receiver`.
     * This error is only thrown when the `mintMaxAssets` function is used.
     * @notice The `mintMaxAssets` function is used to mint the specified amount
     * of shares in exchange of the corresponding underlying assets amount from
     * owner. It also checks that the amount of assets deposited is less or
     * equal to the specified maximum amount.
     * @param owner The address of the owner.
     * @param assets The underlying assets amount to be converted into shares.
     * @param maxAssets The maximum amount of assets to be deposited.
     */
    error ERC4626TooMuchAssetsDeposited(
        address owner, uint256 assets, uint256 maxAssets
    );

    /*
     #############
      CONSTRUCTOR
     #############
    */

    /**
     * @dev The `constructor` function is used to initialize the vault.
     * @param underlying The underlying asset token.
     * @param name The name of the vault.
     * @param symbol The symbol of the vault.
     * @param _decimalsOffset The decimal offset between the underlying asset
     * token and the share token.
     */
    constructor(
        ERC20 underlying,
        string memory name,
        string memory symbol,
        uint8 _decimalsOffset
    ) ERC20(name, symbol) Ownable() {
        _asset = underlying;
        decimalsOffset = _decimalsOffset;
        unchecked {
            _decimalsShares = underlying.decimals() + _decimalsOffset;
        }
        vaultIsOpen = true;
    }

    /*
     ####################
      PAUSABLE OVERRIDES
     ####################
    */

    /**
     * @dev See {Pausable-_pause}.
     * @notice The `pause` function is used to pause the vault.
     * It can only be called by the owner of the contract (`onlyOwner` modifier)
     * when the vault is not paused (`whenNotPaused`).
     * It will disable further deposits but withdrawals will still be enabled.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev See {Pausable-_unpause}.
     * @notice The `unpause` function is used to unpause the vault.
     * It can only be called by the owner of the contract (`onlyOwner` modifier)
     * when the vault is paused (`whenPaused`).
     * It will enable further deposits.
     */

    function unpause() external onlyOwner {
        _unpause();
    }

    /*
     ##################
      ERC-20 OVERRIDES
     ##################
    */

    /**
     * @dev See {IERC20-decimals}.
     * @notice The _decimalShares is equal to underlying asset decimals +
     * decimalsOffset. See constructor for more details about this.
     * @return Amount of decimals of the share token.
     */
    function decimals()
        public
        view
        override(ERC20, IERC20Metadata)
        returns (uint8)
    {
        return _decimalsShares;
    }

    /*
     ####################################
      GENERAL ERC-4626 RELATED FUNCTIONS
     ####################################
    */

    /*
     * @dev The `asset` function is used to return the address of the underlying
     * @return address of the underlying asset.
     */
    function asset() public view returns (address) {
        return address(_asset);
    }

    /**
     * @dev The `totalAssets` function is used to calculate the theoretical
     * total underlying assets owned by the vault.
     * If the vault is locked, the last saved balance is added to the current
     * balance.
     * @notice The `totalAssets` function is used to know what is the
     * theoretical TVL of the vault.
     * @return Amount of the total underlying assets in the vault.
     */
    function totalAssets() public view returns (uint256) {
        if (vaultIsOpen) return _totalAssets();
        return _totalAssets() + lastSavedBalance;
    }

    /**
     * @dev See {IERC4626-convertToShares}.
     * @notice The `convertToShares` function is used to calculate shares amount
     * received in exchange of the specified underlying assets amount.
     * @param assets The underlying assets amount to be converted into shares.
     * @return Amount of shares received in exchange of the specified underlying
     * assets amount.
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /**
     * @dev See {IERC4626-convertToAssets}.
     * @notice The `convertToAssets` function is used to calculate underlying
     * assets amount received in exchange of the specified amount of shares.
     * @param shares The shares amount to be converted into underlying assets.
     * @return Amount of assets received in exchange of the specified shares
     * amount.
     */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /**
     * @dev The `maxDeposit` function is used to calculate the maximum deposit.
     * @notice If the vault is locked or paused, users are not allowed to mint,
     * the maxMint is 0.
     * @ param _ The address of the receiver.
     * @return Amount of the maximum underlying assets deposit amount.
     */
    function maxDeposit(address) public view returns (uint256) {
        return !vaultIsOpen || paused() ? 0 : type(uint256).max;
    }

    /**
     * @dev The `maxMint` function is used to calculate the maximum amount of
     * shares you can mint.
     * @notice If the vault is locked or paused, the maxMint is 0.
     * @ param _ The address of the receiver.
     * @return Amount of the maximum shares mintable for the specified address.
     */
    function maxMint(address) public view returns (uint256) {
        return !vaultIsOpen || paused() ? 0 : type(uint256).max;
    }

    /**
     * @dev The `maxWithdraw` function is used to calculate the maximum amount
     * of withdrawable underlying assets.
     * @notice If the function is called during the lock period the maxWithdraw
     * is `0`.
     * @param owner The address of the owner.
     * @return Amount of the maximum number of withdrawable underlying assets.
     */
    function maxWithdraw(address owner) public view returns (uint256) {
        return vaultIsOpen
            ? _convertToAssets(balanceOf(owner), Math.Rounding.Down)
            : 0;
    }

    /**
     * @dev The `maxRedemm` function is used to calculate the maximum amount of
     * redeemable shares.
     * @notice If the function is called during the lock period the maxRedeem is
     * `0`.
     * @param owner The address of the owner.
     * @return Amount of the maximum number of redeemable shares.
     */
    function maxRedeem(address owner) public view returns (uint256) {
        return vaultIsOpen ? balanceOf(owner) : 0;
    }

    /**
     * @dev The `previewDeposit` function is used to calculate shares amount
     * received in exchange of the specified underlying amount.
     * @param assets The underlying assets amount to be converted into shares.
     * @return Amount of shares received in exchange of the specified underlying
     * assets amount.
     */
    function previewDeposit(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /**
     * @dev The `previewMint` function is used to calculate the underlying asset
     * amount received in exchange of the specified amount of shares.
     * @param shares The shares amount to be converted into underlying assets.
     * @return Amount of underlying assets received in exchange of the specified
     * amount of shares.
     */
    function previewMint(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Up);
    }

    /**
     * @dev The `previewWithdraw` function is used to calculate the shares
     * amount received in exchange of the specified underlying amount.
     * @param assets The underlying assets amount to be converted into shares.
     * @return Amount of shares received in exchange of the specified underlying
     * assets amount.
     */
    function previewWithdraw(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    /**
     * @dev The `previewRedeem` function is used to calculate the underlying
     * assets amount received in exchange of the specified amount of shares.
     * @param shares The shares amount to be converted into underlying assets.
     * @return Amount of underlying assets received in exchange of the specified
     * amount of shares.
     */
    function previewRedeem(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /**
     * @dev The `deposit` function is used to deposit underlying assets into the
     * vault.
     * @notice The `deposit` function is used to deposit underlying assets into
     * the vault.
     * @param assets The underlying assets amount to be converted into shares.
     * @param receiver The address of the shares receiver.
     * @return Amount of shares received in exchange of the
     * specified underlying assets amount.
     */
    function deposit(uint256 assets, address receiver)
        public
        returns (uint256)
    {
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 sharesAmount = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, sharesAmount);

        return sharesAmount;
    }

    /**
     * @dev The `depositMinShares` function is used to deposit underlying assets
     * into the vault. It also checks that the amount of shares minted is greater
     * or equal to the specified minimum amount.
     * @param assets The underlying assets amount to be converted into shares.
     * @param receiver The address of the shares receiver.
     * @param minShares The minimum amount of shares to be minted.
     * @return Amount of shares received in exchange of the specified underlying
     * assets amount.
     */
    function depositMinShares(
        uint256 assets,
        address receiver,
        uint256 minShares
    ) public returns (uint256) {
        uint256 sharesAmount = deposit(assets, receiver);
        if (sharesAmount < minShares) {
            revert ERC4626NotEnoughSharesMinted(
                receiver, sharesAmount, minShares
            );
        }
        return sharesAmount;
    }

    /**
     * @dev The `mint` function is used to mint the specified amount of shares in
     * exchange of the corresponding assets amount from owner.
     * @param shares The shares amount to be converted into underlying assets.
     * @param receiver The address of the shares receiver.
     * @return Amount of underlying assets deposited in exchange of the specified
     * amount of shares.
     */
    function mint(uint256 shares, address receiver) public returns (uint256) {
        uint256 maxShares = maxMint(receiver);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
        }

        uint256 assetsAmount = previewMint(shares);
        _deposit(_msgSender(), receiver, assetsAmount, shares);

        return assetsAmount;
    }

    /**
     * @dev The `mintMaxAssets` function is used to mint the specified amount of
     * shares in exchange of the corresponding underlying assets amount from
     * owner. It also checks that the amount of assets deposited is less or equal
     * to the specified maximum amount.
     * @param shares The shares amount to be converted into underlying assets.
     * @param receiver The address of the shares receiver.
     * @param maxAssets The maximum amount of assets to be deposited.
     * @return Amount of underlying assets deposited in exchange of the specified
     * amount of shares.
     */
    function mintMaxAssets(uint256 shares, address receiver, uint256 maxAssets)
        public
        returns (uint256)
    {
        uint256 assetsAmount = mint(shares, receiver);
        if (assetsAmount > maxAssets) {
            revert ERC4626TooMuchAssetsDeposited(
                receiver, assetsAmount, maxAssets
            );
        }

        return assetsAmount;
    }

    /**
     * @dev The `withdraw` function is used to withdraw the specified underlying
     * assets amount in exchange of a proportional amount of shares.
     * @param assets The underlying assets amount to be converted into shares.
     * @param receiver The address of the shares receiver.
     * @param owner The address of the owner.
     * @return Amount of shares received in exchange of the specified underlying
     * assets amount.
     */
    function withdraw(uint256 assets, address receiver, address owner)
        external
        returns (uint256)
    {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 sharesAmount = previewWithdraw(assets);
        _withdraw(receiver, owner, assets, sharesAmount);

        return sharesAmount;
    }

    /**
     * @dev The `redeem` function is used to redeem the specified amount of
     * shares in exchange of the corresponding underlying assets amount from
     * owner.
     * @param shares The shares amount to be converted into underlying assets.
     * @param receiver The address of the shares receiver.
     * @param owner The address of the owner.
     * @return Amount of underlying assets received in exchange of the specified
     * amount of shares.
     */
    function redeem(uint256 shares, address receiver, address owner)
        external
        returns (uint256)
    {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        uint256 assetsAmount = previewRedeem(shares);
        _withdraw(receiver, owner, assetsAmount, shares);

        return assetsAmount;
    }

    /**
     * @dev The `_totalAssets` function is used to return the current assets
     * balance of the vault contract.
     * @notice The `_totalAssets` is used to know the balance of underlying of
     * the vault contract without
     * taking care of any theoretical external funds of the vault.
     * @return Amount of underlying assets balance actually contained into the
     * vault contract.
     */
    function _totalAssets() internal view returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support
     * for rounding direction.
     * @param assets Theunderlying assets amount to be converted into shares.
     * @param rounding The rounding direction.
     * @return Amount of shares received in exchange of the specified underlying
     * assets amount.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        returns (uint256)
    {
        return assets.mulDiv(
            totalSupply() + 10 ** decimalsOffset, totalAssets() + 1, rounding
        );
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support
     * for rounding direction.
     * @param shares The shares amount to be converted into underlying assets.
     * @param rounding The rounding direction.
     * @return Amount of underlying assets received in exchange of the
     * specified amount of shares.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        returns (uint256)
    {
        return shares.mulDiv(
            totalAssets() + 1, totalSupply() + 10 ** decimalsOffset, rounding
        );
    }

    /**
     * @dev The `_deposit` function is used to deposit the specified underlying
     * assets amount in exchange of a proportionnal amount of shares.
     * @param caller The address of the caller.
     * @param receiver The address of the shares receiver.
     * @param assets The underlying assets amount to be converted into shares.
     * @param shares The shares amount to be converted into underlying assets.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal {
        // If _asset is ERC777, transferFrom can trigger a reentrancy BEFORE the
        // transfer happens through the tokensToSend hook. On the other hand,
        // the tokenReceived hook, that is triggered after the transfer,calls
        // the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any
        // reentrancy would happen before the assets are transferred and before
        // the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev The function `_withdraw` is used to withdraw the specified
     * underlying assets amount in exchange of a proportionnal amount of shares by
     * specifying all the params.
     * @notice The `withdraw` function is used to withdraw the specified
     * underlying assets amount in exchange of a proportionnal amount of shares.
     * @param receiver The address of the shares receiver.
     * @param owner The address of the owner.
     * @param assets The underlying assets amount to be converted into shares.
     * @param shares The shares amount to be converted into underlying assets.
     */
    function _withdraw(
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal {
        if (_msgSender() != owner) {
            _spendAllowance(owner, _msgSender(), shares);
        }

        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(_msgSender(), receiver, owner, assets, shares);
    }

    /*
     ####################################
      AMPHOR SYNTHETIC RELATED FUNCTIONS
     ####################################
    */

    /**
     * @dev The `start` function is used to start the lock period of the vault.
     * It is the only way to lock the vault. It can only be called by the owner
     * of the contract (`onlyOwner` modifier).
     */
    function start() external onlyOwner {
        if (!vaultIsOpen) revert VaultIsLocked();

        lastSavedBalance = _totalAssets();
        vaultIsOpen = false;
        _asset.safeTransfer(owner(), lastSavedBalance);

        emit EpochStart(block.timestamp, lastSavedBalance, totalSupply());
    }

    /**
     * @dev The `end` function is used to end the lock period of the vault.
     * @notice The `end` function is used to end the lock period of the vault.
     * It can only be called by the owner of the contract (`onlyOwner` modifier)
     * and only when the vault is locked.
     * If there are profits, the performance fees are taken and sent to the
     * owner of the contract.
     * @param assetReturned The underlying assets amount to be deposited into
     * the vault.
     */
    function end(uint256 assetReturned) external onlyOwner {
        if (vaultIsOpen) revert VaultIsOpen();

        uint256 fees;

        if (assetReturned > lastSavedBalance && feesInBps > 0) {
            uint256 profits;
            unchecked {
                profits = assetReturned - lastSavedBalance;
            }
            fees = (profits).mulDiv(feesInBps, 10000, Math.Rounding.Up);
        }

        SafeERC20.safeTransferFrom(
            _asset, _msgSender(), address(this), assetReturned - fees
        );

        vaultIsOpen = true;

        emit EpochEnd(
            block.timestamp,
            lastSavedBalance,
            assetReturned,
            fees,
            totalSupply()
        );

        lastSavedBalance = 0;
    }

    /**
     * @dev The `setFees` function is used to modify the protocol fees.
     * @notice The `setFees` function is used to modify the perf fees.
     * It can only be called by the owner of the contract (`onlyOwner` modifier).
     * It can't exceed 30% (3000 in BPS).
     * @param newFees The new perf fees to be applied.
     */
    function setFees(uint16 newFees) external onlyOwner {
        if (newFees > 3000) revert FeesTooHigh();
        feesInBps = newFees;
        emit FeesChanged(feesInBps, newFees);
    }

    /**
     * @dev The `claimToken` function is used to claim other tokens that have
     * been sent to the vault.
     * @notice The `claimToken` function is used to claim other tokens that have
     * been sent to the vault.
     * It can only be called by the owner of the contract (`onlyOwner` modifier).
     * @param token The IERC20 token to be claimed.
     */
    function claimToken(IERC20 token) external onlyOwner {
        if (token == _asset) revert CannotClaimAsset();
        token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
    }
}
