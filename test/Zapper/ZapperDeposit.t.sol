// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../src/VaultZapper.sol";
import "./OffChainCalls.t.sol";

contract VaultZapperDeposit is OffChainCalls {
    VaultZapper zapper;
    SigUtils internal sigUtils;
    uint256 userPrivateKey = _usersPk[0];
    address user = _users[0];

    using SafeERC20 for IERC20;

    function setUp() public {
        zapper = new VaultZapper();
    }

    function test_zapAndDepositUsdcWSTETH() public {
        Swap memory usdcToWstEth =
            Swap(_router, _USDC, _WSTETH, 1500 * 1e6, 1, address(0), 20);
        _zapAndDeposit(usdcToWstEth);
    }

    function test_failZapAndDepositUsdcWSTETHUnknownReason() public {
        Swap memory usdcToWstEth =
            Swap(_router, _USDC, _WSTETH, 150000000 * 1e6, 1, address(0), 0);
        _failZapAndDeposit(usdcToWstEth, 150000000 * 1e6);
    }

    function test_failZapAndDepositERC20PlusEth() public {
        Swap memory usdcToWstEth =
            Swap(_router, _USDC, _WSTETH, 1500 * 1e6, 1, address(0), 30);
        _failZapAndDeposit_eth(usdcToWstEth, 1500 * 1e6);
    }

    function test_inconsistantZapAndDepositUsdcWSTETH() public {
        Swap memory usdcToWstEth = Swap(
            _router,
            IERC20(_USDC),
            IERC20(_WSTETH),
            1000 * 1e6,
            1,
            address(0),
            20
        );
        _failZapAndDeposit(usdcToWstEth, 1500 * 1e6);
    }

    function test_failZapAndDepositUsdcWSTETH() public {
        Swap memory usdcToWstEth = Swap(
            _router,
            IERC20(_USDC),
            IERC20(_WSTETH),
            1000 * 1e6,
            type(uint256).max,
            address(0),
            20
        );
        _failZapAndDeposit(usdcToWstEth, 1500 * 1e6);
    }

    function test_zapAndDepositEthWSTETH() public {
        Swap memory ethToWstEth =
            Swap(_router, _ETH, _WSTETH, 1e18, 1, address(0), 200);
        _zapAndDeposit_eth(ethToWstEth);
    }

    function test_inconsistantZapAndDepositEthWSTETH() public {
        Swap memory ethToWstEth = Swap(
            _router, IERC20(_ETH), IERC20(_WSTETH), 1e18, 1, address(0), 10000
        );
        _failZapAndDeposit_eth(ethToWstEth, 2e18);
    }

    function test_inconsistantZapAndDepositEthWSTETHNullShares() public {
        Swap memory ethToWstEth = Swap(
            _router, IERC20(_ETH), IERC20(_WSTETH), 1e18, 0, address(0), 10000
        );
        _failZapAndDeposit_eth(ethToWstEth, 2e18);
    }

    function test_inconsistantZapAndDepositUsdcWSTETHNullShares() public {
        Swap memory usdcToWstEth = Swap(
            _router,
            IERC20(_USDC),
            IERC20(_WSTETH),
            1000 * 1e6,
            0,
            address(0),
            20
        );
        _failZapAndDeposit(usdcToWstEth, 1500 * 1e6);
    }

    function _zapAndDeposit(Swap memory params) public {
        bytes memory swapData =
            _getSwapData(address(zapper), address(zapper), params);
        _setUpVaultAndZapper(params.tokenOut);
        _getTokenIn(params);
        uint256 beforeDep = _vault.balanceOf(address(this));
        if (keccak256(swapData) == keccak256(hex"")) vm.expectRevert();
        zapper.zapAndDeposit(
            params.tokenIn,
            _vault,
            params.router,
            params.amount,
            params.minAmount,
            swapData
        );
        uint256 afterDep = _vault.balanceOf(address(this));
        if (keccak256(swapData) != keccak256(hex""))
            assertTrue(afterDep > beforeDep, "Deposit failed");
    }

    function _failZapAndDeposit(Swap memory params, uint256 amount) public {
        bytes memory swapData =
            _getSwapData(address(zapper), address(zapper), params);
        _setUpVaultAndZapper(params.tokenOut);
        _getTokenIn(params);
        vm.expectRevert();
        zapper.zapAndDeposit(
            params.tokenIn,
            _vault,
            params.router,
            amount,
            params.minAmount,
            swapData
        );
    }

    function _zapAndDeposit_eth(Swap memory params) public {
        bytes memory swapData =
            _getSwapData(address(zapper), address(zapper), params);
        _setUpVaultAndZapper(params.tokenOut);
        _getTokenIn(params);
        uint256 beforeDep = _vault.balanceOf(address(this));
        if (keccak256(swapData) == keccak256(hex"")) vm.expectRevert();
        zapper.zapAndDeposit{value: params.amount}(
            params.tokenIn, _vault, params.router, params.amount, params.minAmount, swapData
        );
        uint256 afterDep = _vault.balanceOf(address(this));
        if (keccak256(swapData) != keccak256(hex""))
            assertTrue(afterDep > beforeDep, "Deposit failed");
    }

    function _failZapAndDeposit_eth(Swap memory params, uint256 amount)
        public
    {
        bytes memory swapData = _getSwapData(address(zapper), address(zapper), params);
        _setUpVaultAndZapper(params.tokenOut);
        _getTokenIn(params);
        vm.expectRevert();
        zapper.zapAndDeposit{value: amount}(
            params.tokenIn, _vault, params.router, params.amount, params.minAmount, swapData
        );
    }

    function test_fail_zapAndDeposit_NotEnoughShares() public {
        Swap memory params = Swap(
            _router,
            IERC20(_USDC),
            IERC20(_WSTETH),
            1500 * 1e6,
            type(uint256).max,
            address(0),
            100
        );
        bytes memory swapData = _getSwapData(address(zapper), address(zapper), params);
        _setUpVaultAndZapper(params.tokenOut);
        _getTokenIn(params);
        uint256 beforeDepTokenIn =
            (IERC20(address(params.tokenIn)).balanceOf(address(this)));

        uint256 value = params.tokenIn == IERC20(_ETH) ? params.amount : 0;
        vm.expectRevert();
        zapper.zapAndDeposit{value: value}(
            params.tokenIn,
            _vault,
            params.router,
            params.amount,
            params.minAmount,
            swapData
        );
        uint256 afterDepTokenIn =
            (IERC20(address(params.tokenIn)).balanceOf(address(this)));
        assertTrue(afterDepTokenIn == beforeDepTokenIn, "Deposit failed");
    }

    function test_fail_zapAndDeposit_RouterFails() public {
        Swap memory params = Swap(
            _router,
            IERC20(_USDC),
            IERC20(_WSTETH),
            1500 * 1e6,
            type(uint256).max,
            address(0),
            100
        );
        bytes memory swapData = _getSwapData(address(zapper), address(zapper), params);
        if (keccak256(swapData) != keccak256(hex"")) swapData[0] = hex"00";
        _setUpVaultAndZapper(params.tokenOut);
        _getTokenIn(params);
        uint256 beforeDepTokenIn =
            (IERC20(address(params.tokenIn)).balanceOf(address(this)));

        uint256 value = params.tokenIn == IERC20(_ETH) ? params.amount : 0;
        vm.expectRevert();
        zapper.zapAndDeposit{value: value}(
            params.tokenIn,
            _vault,
            params.router,
            params.amount,
            params.minAmount,
            swapData
        );
        uint256 afterDepTokenIn =
            (IERC20(address(params.tokenIn)).balanceOf(address(this)));
        assertTrue(afterDepTokenIn == beforeDepTokenIn, "Deposit failed");
    }

    function _setUpVaultAndZapper(IERC20 asset) public {
        _vault = new AmphorSyntheticVault(ERC20(address(asset)), "", "", 12);
        if (!zapper.authorizedRouters(_router)) {
            zapper.toggleRouterAuthorization(_router);
        }
        if (!zapper.authorizedVaults(_vault)) {
            zapper.toggleVaultAuthorization(_vault);
        }
        zapper.approveTokenForRouter(IERC20(_vault.asset()), _router);
    }

    function _getTokenIn(Swap memory params) public {
        if (params.tokenIn != _ETH) {
            if (params.tokenInWhale == address(0)) {
                deal(address(params.tokenIn), address(this), 1000 * 1e18);
            } else {
                vm.prank(params.tokenInWhale);
                SafeERC20.safeTransfer(
                    params.tokenIn, address(this), 1000 * 1e18
                );
            }
            SafeERC20.forceApprove(
                IERC20(params.tokenIn), address(zapper), type(uint256).max
            );
        }
        deal(address(this), 1000 * 1e18);
    }
}
