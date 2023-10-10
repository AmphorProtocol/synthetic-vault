// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./SyntheticBase.t.sol";

contract SyntheticBasicTests is SyntheticBaseTests {
    function test_Name() public {
        assertEq(_synthVault.name(), "Amphor Synthetic Vault");
    }

    function test_Owner() public {
        assertEq(_synthVault.owner(), address(this));
    }

    function test_Symbol() public {
        assertEq(_synthVault.symbol(), "ASV");
    }

    function test_Underlying() public {
        assertEq(_synthVault.asset(), address(_underlying));
    }

    function test_AssetAddress() public {
        assertEq(_synthVault.asset(), address(_underlying));
    }

    function test_DecimalOffset() public {
        assertEq(_synthVault.decimalsOffset(), _decimalOffset);
    }

    function test_TotalSupply() public {
        assertEq(_synthVault.totalSupply(), 0);
    }

    function test_BalanceOf() public {
        assertEq(_synthVault.balanceOf(address(this)), 0);
    }

    function test_Allowance() public {
        assertEq(_synthVault.allowance(address(this), address(this)), 0);
    }

    function test_Approve() public {
        _synthVault.approve(address(this), 100);
        assertEq(_synthVault.allowance(address(this), address(this)), 100);
    }

    function test_perfFeesOver30() public {
        vm.expectRevert(AmphorSyntheticVault.FeesTooHigh.selector);
        _synthVault.setFees(31 * 100);
    }

    function test_claimUnderlying() public {
        giveEthUnderlyingAndApprove(_signer);
        vm.prank(_signer);
        _synthVault.deposit(100, _signer);

        vm.expectRevert(AmphorSyntheticVault.CannotClaimAsset.selector);
        _synthVault.claimToken(IERC20(_underlying));
    }

    function test_claimOtherToken() public {
        deal(address(_usdt), address(_synthVault), 10 * 10 ** 6);

        _synthVault.claimToken(IERC20(_usdt));
    }

    function test_totalAsset() public {
        giveEthUnderlyingAndApprove(_signer);
        vm.prank(_signer);
        _synthVault.deposit(100, _signer);

        assertEq(_synthVault.totalAssets(), 100);
    }

    function test_MaxDeposit() public {
        assertEq(
            _synthVault.maxDeposit(address(0)),
            type(uint256).max,
            "Max deposit should be equal to total supply of underlying"
        );
    }

    function test_MaxDepositAfterStart() public {
        _synthVault.start();
        assertEq(
            _synthVault.maxDeposit(address(0)),
            0,
            "Max deposit should be equal to zero after start"
        );
    }

    function test_MaxMint() public {
        assertEq(
            _synthVault.maxMint(address(0)),
            UINT256_MAX,
            "Max mint should be equal to total supply of underlying "
        );
    }

    function test_MaxMintAfterStart() public {
        _synthVault.start();
        assertEq(
            _synthVault.maxMint(address(0)),
            0,
            "Max mint should be equal to total supply of underlying "
        );
    }

    function test_maxWithdraw() public {
        assertEq(
            _synthVault.maxDeposit(address(0)),
            type(uint256).max,
            "Max deposit should be equal to total supply of underlying"
        );
    }

    function test_maxWithdrawAfterStart() public {
        _synthVault.start();
        assertEq(
            _synthVault.maxWithdraw(address(0)),
            0,
            "Max withdraw should be 0 after start"
        );
    }

    function test_MaxRedeem() public {
        assertEq(
            _synthVault.maxRedeem(address(this)),
            ERC20(_synthVault).balanceOf(address(this)),
            "Max redeem should be equal to total supply of underlying"
        );
    }

    function test_MaxRedeemAfterStart() public {
        _synthVault.start();
        assertEq(
            _synthVault.maxRedeem(address(this)),
            0,
            "Max redeem should be equal to total supply of underlying"
        );
    }

    function test_decimals() public {
        assertEq(
            _synthVault.decimals(),
            ERC20(_underlying).decimals() + _decimalOffset,
            "Max deposit should be equal to total supply of underlying after start"
        );
    }

    function test_totalAssetsAfterStartWithoutDonation() public {
        _synthVault.start();
        assertEq(
            _synthVault.totalAssets(),
            _synthVault.lastSavedBalance(),
            "Total assets should be total supply of underlying after start"
        );
    }

    function test_totalAssetsAfterStartWithDonation() public {
        _synthVault.start();
        uint256 donationAmount = 100;
        deal(address(_underlying), address(_synthVault), donationAmount);
        assertEq(
            _synthVault.totalAssets(),
            _synthVault.lastSavedBalance() + donationAmount,
            "Total assets should be total supply of underlying after start + donation"
        );
    }
}
