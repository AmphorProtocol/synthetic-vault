// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {BaseProperties} from "../Core_v0/BaseProperties.t.sol";
import {AmphorSyntheticVaultWithPermit} from
    "../../src/AmphorSyntheticVaultWithPermit.sol";

import {
    ERC4626,
    ERC20
} from "@openzeppelin-v4.9.3/contracts/token/ERC20/extensions/ERC4626.sol";

abstract contract GlobalSynthetic is BaseProperties {
    uint8 internal _decimalOffset = uint8(vm.envUint("DECIMALS_OFFSET_USDC")); // 12 by default
    uint16 internal _fees = uint16(vm.envUint("INITIAL_FEES_AMOUNT")); // 20.00% by default

    AmphorSyntheticVaultWithPermit internal _synthVault;

    constructor() {
        _bootstrapAmount = vm.envUint("BOOTSTRAP_AMOUNT_SYNTHETIC_USDC");
        _amphorLabs = vm.envAddress("AMPHORLABS_ADDRESS");
        _vaultName = vm.envString("SYNTHETIC_USDC_V0_NAME");
        _vaultSymbol = vm.envString("SYNTHETIC_USDC_V0_SYMBOL");

        _underlying = _USDC;
        _vaultDecimals = _decimalOffset + _underlying.decimals();

        // Deploy the AmphorSyntheticVault contract
        _synthVault = new AmphorSyntheticVaultWithPermit(
            _underlying,
            _vaultName,
            _vaultSymbol,
            _decimalOffset
        );

        _initialMintAmount = _synthVault.previewDeposit(_bootstrapAmount);

        _synthVault.setFees(_fees);

        // Bootstrap the vault with underlying tokens (USDC)
        deal(address(_USDC), address(this), _bootstrapAmount);
        _USDC.approve(address(_synthVault), _bootstrapAmount);
        _synthVault.deposit(_bootstrapAmount, address(this));

        _vault = ERC4626(address(_synthVault));
    }
}
