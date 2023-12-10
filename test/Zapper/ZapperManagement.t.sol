// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../src/VaultZapper.sol";
import "./OffChainCalls.t.sol";

contract VaultZapperManagement is OffChainCalls {
    VaultZapper zapper;
    SigUtils internal sigUtils;
    uint256 userPrivateKey = _usersPk[0];
    address user = _users[0];

    using SafeERC20 for IERC20;

    function setUp() public {
        zapper = new VaultZapper();
    }

    function test_removeVaultAuthorization() public {
        _setUpVaultAndZapper(_WSTETH);
        uint256 allowanceBeforeDisabling =
            _WSTETH.allowance(address(zapper), address(_vault));
        zapper.toggleVaultAuthorization(_vault);
        uint256 allowanceAfterDisabling =
            _WSTETH.allowance(address(zapper), address(_vault));
        assertTrue(
            allowanceBeforeDisabling > 0 && allowanceAfterDisabling == 0,
            "Router disabling failed"
        );
    }

    function test_fail_removeVaultAuthorization_notOwner() public {
        _setUpVaultAndZapper(_WSTETH);
        vm.startPrank(user);
        vm.expectRevert();
        zapper.toggleVaultAuthorization(_vault);
    }

    function test_withdrawToken() public {
        _setUpVaultAndZapper(_WSTETH);
        uint256 amount = _USDT.balanceOf(address(this));
        deal(address(_USDT), address(zapper), 1000 * 1e6);
        zapper.withdrawToken(_USDT);
        uint256 amountAfter = _USDT.balanceOf(address(this));
        assertTrue(amount < amountAfter, "No dust collected");
    }

    function test_failWithdrawToken_notOwner() public {
        _setUpVaultAndZapper(_WSTETH);
        vm.startPrank(user);
        vm.expectRevert();
        zapper.withdrawToken(_USDT);
    }

    function test_withdrawNativeToken() public {
        _setUpVaultAndZapper(_WSTETH);
        uint256 amount = address(this).balance;
        deal(address(zapper), 1000 * 1e6);
        zapper.withdrawNativeToken();
        uint256 amountAfter = address(this).balance;
        assertTrue(amount < amountAfter, "No dust collected");
    }

    function test_fail_withdrawNativeToken_notOwner() public {
        _setUpVaultAndZapper(_WSTETH);
        vm.startPrank(user);
        vm.expectRevert();
        zapper.withdrawNativeToken();
    }

    function test_pauseZapper() public {
        zapper.pause();
        assertTrue(zapper.paused(), "Zapper not paused");
    }

    function test_fail_pauseZapper_notOwner() public {
        vm.startPrank(user);
        vm.expectRevert();
        zapper.pause();
    }

    function test_fail_unpauseZapper() public {
        vm.expectRevert();
        zapper.unpause();
    }

    function test_fail_unpauseZapper_notOwner() public {
        zapper.pause();
        vm.startPrank(user);
        vm.expectRevert();
        zapper.unpause();
    }

    function test_unpauseZapper() public {
        zapper.pause();
        zapper.unpause();
        assertTrue(!zapper.paused(), "Zapper not unpaused");
    }

    function test_fail_approveTokenForRouter_notOwner() public {
        vm.startPrank(user);
        vm.expectRevert();
        zapper.approveTokenForRouter(_WSTETH, _router);
    }

    function test_fail_toggleRouterAuthorization_notOwner() public {
        vm.startPrank(user);
        vm.expectRevert();
        zapper.toggleRouterAuthorization(_router);
    }

    function _setUpVaultAndZapper(IERC20 tokenOut) public {
        _vault = new AmphorSyntheticVault(ERC20(address(tokenOut)), "", "", 12);
        if (!zapper.authorizedRouters(_router)) {
            zapper.toggleRouterAuthorization(_router);
        }
        if (!zapper.authorizedVaults(_vault)) {
            zapper.toggleVaultAuthorization(_vault);
        }
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

    receive() external payable {}

    
}
