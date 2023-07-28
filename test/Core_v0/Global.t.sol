// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../../lib/forge-std/src/console.sol";
import "../../lib/forge-std/src/Test.sol";

import {ERC4626} from
    "../../lib/openzeppelin-contracts-v4.9.3/contracts/token/ERC20/extensions/ERC4626.sol";

import "../../src/AmphorSyntheticVaultWithPermit.sol";

abstract contract GlobalTest is Test {
    ERC20 internal immutable _USDC = ERC20(vm.envAddress("USDC_MAINNET"));
    ERC20 internal immutable _WETH = ERC20(vm.envAddress("WETH_MAINNET"));
    ERC20 internal immutable _WBTC = ERC20(vm.envAddress("WBTC_MAINNET"));
    ERC20 internal immutable _USDT = ERC20(vm.envAddress("USDT_MAINNET"));

    ERC20 internal _underlying;

    ERC4626 internal immutable _vault;

    // Random signer address
    address[] internal _users = [
        0xfeFf51Dd22131c2CB32E62E8e6032620a5142aFf,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x8463992C66a1AE1cD4A084a7bC3c1d545A26e280,
        0xd64A15200136393a88F94965Cc6854Ce9a4A62b0,
        0xf88893837ddBaED62C96389C5ACF85f114655b68,
        0x4C41f6d02BD6155B5841049B79f963E599b33d1B,
        0xD088783912A3C1DaBCcAd87655BAFA924453E23f,
        0xDD3fD56D402161748b3a553c8CE1D604A825918b,
        0x4180e502E4Ac215ff5d1fE409F2B8502074b7a84
    ];

    uint256 internal _bootstrapAmount;
    uint256 internal _initialMintAmount;
    uint256 internal _vaultDecimals;
    address internal _amphorLabs;
    string internal _vaultName;
    string internal _vaultSymbol;
}
