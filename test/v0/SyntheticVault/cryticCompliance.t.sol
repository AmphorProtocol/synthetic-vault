// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {CryticERC4626PropertyTests} from
    "@crytic/ERC4626/ERC4626PropertyTests.sol";
// this token _must_ be the vault's underlying asset
import {TestERC20Token} from "@crytic/ERC4626/util/TestERC20Token.sol";
// change to your vault implementation
import {
    AmphorSyntheticVaultWithPermit,
    ERC20
} from "@src/AmphorSyntheticVaultWithPermit.sol";

contract CryticERC4626PropertyTestsSynth is CryticERC4626PropertyTests {
    constructor() {
        TestERC20Token _asset = new TestERC20Token("Test Token", "TT", 6);
        AmphorSyntheticVaultWithPermit _vault =
        new AmphorSyntheticVaultWithPermit(
                ERC20(address(_asset)),
                "Test Vault",
                "TV",
                12
            );
        initialize(address(_vault), address(_asset), false);
    }
}
