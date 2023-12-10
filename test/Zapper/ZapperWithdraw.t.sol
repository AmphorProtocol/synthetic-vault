// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./OffChainCalls.t.sol";

contract ZapperWithdrawTest is OffChainCalls {
    VaultZapper zapper;
    SigUtils internal sigUtils;
    uint256 userPrivateKey = _usersPk[0];
    address user = _users[0];

    function setUp() public {
        zapper = new VaultZapper();
        _setUpVaultAndZapper(IERC20(vm.envAddress("WSTETH_MAINNET")));
    }

    function _setUpVaultAndZapper(IERC20 tokenIn) public {
        _vault = new AmphorSyntheticVault(ERC20(address(tokenIn)), "", "", 12);

        if (!zapper.authorizedRouters(_router)) {
            zapper.toggleRouterAuthorization(_router);
        }

        if (!zapper.authorizedVaults(_vault)) {
            zapper.toggleVaultAuthorization(_vault);
        }
    }

    function dealEverybody(uint256 assets) public {
        deal(vm.envAddress("WSTETH_MAINNET"), address(this), assets);
        IERC20(vm.envAddress("WSTETH_MAINNET")).approve(
            address(_vault), type(uint256).max
        );
        _vault.deposit(assets, address(this));
        deal(address(this), 1000 * 1e18); // get some eth
    }

    function test_withdrawAndZapDAI() public {
        _vault.approve(address(zapper), type(uint256).max);

        dealEverybody(1 * 1e18);

        Swap memory wstEthToDai = Swap(
            _router,
            ERC20(vm.envAddress("WSTETH_MAINNET")),
            IERC20(vm.envAddress("DAI_MAINNET")),
            1 * 1e18,
            0,
            address(0),
            30
        );

        _withdrawAndZap(wstEthToDai);
    }

    function test_inconsistantWithdrawAndZapDAI() public {
        _vault.approve(address(zapper), type(uint256).max);

        dealEverybody(2 * 1e18);

        Swap memory wstEthToDai = Swap(
            _router,
            ERC20(vm.envAddress("WSTETH_MAINNET")),
            IERC20(vm.envAddress("DAI_MAINNET")),
            1 * 1e18,
            0,
            address(0),
            30
        );

        _failWithdrawAndZap(wstEthToDai, 2 * 1e18);
    }

    function test_redeemAndZapDAI() public {
        _vault.approve(address(zapper), type(uint256).max);

        dealEverybody(1 * 1e18);
        uint256 previewedRedeem =
            _vault.previewRedeem(_vault.balanceOf(address(this)));
        console.log("previewedRedeem_value", previewedRedeem);

        Swap memory wstEthToDai = Swap(
            _router,
            ERC20(vm.envAddress("WSTETH_MAINNET")),
            IERC20(vm.envAddress("DAI_MAINNET")),
            previewedRedeem,
            0,
            address(0),
            30
        );

        _redeemAndZap(wstEthToDai);
    }

    function test_inconsistantRedeemAndZapDAI() public {
        _vault.approve(address(zapper), type(uint256).max);

        dealEverybody(2 * 1e18);
        uint256 previewedRedeem =
            _vault.previewRedeem(_vault.balanceOf(address(this)) / 2);
        console.log("previewedRedeem_value", previewedRedeem);

        Swap memory wstEthToDai = Swap(
            _router,
            ERC20(vm.envAddress("WSTETH_MAINNET")),
            IERC20(vm.envAddress("DAI_MAINNET")),
            previewedRedeem,
            0,
            address(0),
            30
        );

        _failRedeemAndZap(wstEthToDai);
    }

    function _withdrawAndZap(Swap memory params) public {
        bytes memory swapData =
            _getSwapData(address(zapper), address(this), params);

        _vault.approve(address(zapper), type(uint256).max);

        uint256 beforeWith = (_vault.balanceOf(address(this)));
        uint256 zappedBefore = IERC20(params.tokenOut).balanceOf(address(this));

        zapper.approveTokenForRouter(params.tokenIn, params.router);

        if (keccak256(swapData) == keccak256(hex"")) vm.expectRevert();
        zapper.withdrawAndZap(_vault, _router, 1 * 1e18, swapData);

        uint256 afterWith = (_vault.balanceOf(address(this)));
        uint256 zappedAfter = IERC20(params.tokenOut).balanceOf(address(this));
        console.log("beforeWith", beforeWith);
        console.log("afterWith", afterWith);
        console.log("zappedBefore", zappedBefore);
        console.log("zappedAfter", zappedAfter);

        if (keccak256(swapData) != keccak256(hex"")) {
            assertTrue(beforeWith > afterWith, "Withdraw failed");
            assertTrue(
                zappedBefore < zappedAfter,
                "Zap failed because no tokens were received"
            );
        }
    }

    function _failWithdrawAndZap(Swap memory params, uint256 amount) public {
        bytes memory swapData =
            _getSwapData(address(zapper), address(this), params);

        _vault.approve(address(zapper), type(uint256).max);

        zapper.approveTokenForRouter(params.tokenIn, params.router);
        vm.expectRevert();
        zapper.withdrawAndZap(_vault, _router, amount, swapData);
    }

    function _redeemAndZap(Swap memory params) public {
        bytes memory swapData =
            _getSwapData(address(zapper), address(this), params);

        _vault.approve(address(zapper), type(uint256).max);

        uint256 beforeRedeem = (_vault.balanceOf(address(this)));
        uint256 zappedBefore = IERC20(params.tokenOut).balanceOf(address(this));

        zapper.approveTokenForRouter(params.tokenIn, params.router);

        uint256 sharesBalance = _vault.balanceOf(address(this));
        if (keccak256(swapData) == keccak256(hex"")) vm.expectRevert();
        zapper.redeemAndZap(_vault, _router, sharesBalance, swapData);
        uint256 afterRedeem = (_vault.balanceOf(address(this)));
        uint256 zappedAfter = IERC20(params.tokenOut).balanceOf(address(this));
        console.log("beforeWith", beforeRedeem);
        console.log("afterWith", afterRedeem);
        console.log("zappedBefore", zappedBefore);
        console.log("zappedAfter", zappedAfter);

        if (keccak256(swapData) != keccak256(hex"")) {
            assertTrue(beforeRedeem > afterRedeem, "Redeem failed");
            assertTrue(
                zappedBefore < zappedAfter,
                "Zap failed because no tokens were received"
            );
        }
    }

    function _failRedeemAndZap(Swap memory params) public {
        bytes memory swapData =
            _getSwapData(address(zapper), address(this), params);

        _vault.approve(address(zapper), type(uint256).max);

        zapper.approveTokenForRouter(params.tokenIn, params.router);

        uint256 assets = _vault.balanceOf(address(this));

        vm.expectRevert();
        zapper.redeemAndZap(_vault, _router, assets, swapData);
    }
}
