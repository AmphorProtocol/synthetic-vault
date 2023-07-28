//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {GlobalSynthetic} from "../GlobalSynthetic.t.sol";
import {UtilsSynthetic} from "../UtilsSynthetic.t.sol";

contract BaseProperties is GlobalSynthetic, UtilsSynthetic {
// function test_DecimalOffset() public {
//     assertEq(_synthVault.decimalsOffset(), _decimalOffset);
// }

// function test_LastsavedBalanceAtDeployment() public {
//     assertEq(_synthVault.lastSavedBalance(), 0);
// }

// function test_Fees() public {
//     assertEq(_synthVault.feesInBps(), 20000);
// }

// function test_VaultIsOpen() public {
//     assertEq(_synthVault.vaultIsOpen(), true);
// }

// function test_Name() public {
//     assertEq(_synthVault.name(), _vaultName);
// }

// function test_Owner() public {
//     assertEq(_synthVault.owner(), address(this));
// }

// function test_Symbol() public {
//     assertEq(_synthVault.symbol(), "ASV");
// }

// function test_Underlying() public {
//     assertEq(_synthVault.asset(), address(_USDC));
// }

// function test_AssetAddress() public {
//     assertEq(_synthVault.asset(), address(_USDC));
// }

// function test_TotalSupply() public {
//     assertEq(_synthVault.totalSupply(), 0);
// }

// function test_BalanceOf() public {
//     assertEq(_synthVault.balanceOf(address(this)), 0);
// }

// function test_Allowance() public {
//     assertEq(_synthVault.allowance(address(this), address(this)), 0);
// }

// function test_Approve() public {
//     _synthVault.approve(address(this), 100);
//     assertEq(_synthVault.allowance(address(this), address(this)), 100);
// }

/*
    function test_perfFeesOver30() public {
        vm.expectRevert(AmphorSyntheticVaultWithPermit.FeesTooHigh.selector);
        _synthVault.setFees(31 * 100);
    }

    function test_claimUnderlying() public {
        giveEthUnderlyingAndApprove(_signer);
        vm.prank(_signer);
        _synthVault.deposit(100, _signer);

        vm.expectRevert(AmphorSyntheticVaultWithPermit.CannotClaimAsset.selector);
        _synthVault.claimToken(IERC20(USDC));
    }
    */
}
