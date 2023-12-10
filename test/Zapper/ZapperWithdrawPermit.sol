// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../src/VaultZapper.sol";
import "../utils/SigUtils.sol";
import "./OffChainCalls.t.sol";

contract ZapperWithdrawPermitTest is OffChainCalls {
    VaultZapper zapper;
    SigUtils internal sigUtils;
    uint256 userPrivateKey = 0xA11CE;
    address user = vm.addr(userPrivateKey);

    function setUp() public {
        zapper = new VaultZapper();
        _setUpVaultAndZapper(IERC20(vm.envAddress("WSTETH_MAINNET")));
    }

    function test_withdrawAndZapPermit_WSTETHUSDC() public {
        zapper.approveTokenForRouter(_WSTETH, _router);
        vm.startPrank(user);
        _withdrawAndZapPermit(
            Swap(
                _router,
                IERC20(_WSTETH),
                IERC20(_USDC),
                1 * 1e18,
                0,
                address(0),
                20
            )
        );
        vm.stopPrank();
    }

    function test_redeemAndZapPermit_WSTETHUSDC() public {
        zapper.approveTokenForRouter(_WSTETH, _router);
        vm.startPrank(user);
        dealEverybody(1 * 1e18);
        _redeemAndZapPermit(
            Swap(
                _router,
                IERC20(_WSTETH),
                IERC20(_USDC),
                _vault.previewRedeem(_vault.balanceOf(user)),
                0,
                address(0),
                20
            )
        );
        vm.stopPrank();
    }

    function dealEverybody(uint256 assets) public {
        deal(vm.envAddress("WSTETH_MAINNET"), user, assets);
        IERC20(vm.envAddress("WSTETH_MAINNET")).approve(
            address(_vault), type(uint256).max
        );
        _vault.deposit(assets, user);
        deal(user, 1000 * 1e18); // get some eth
    }

    function _withdrawAndZapPermit(Swap memory params) public {
        ERC20Permit shareToken = ERC20Permit(address(_vault));
        sigUtils = new SigUtils(shareToken.DOMAIN_SEPARATOR());
        bytes memory swapData = _getSwapData(address(zapper), user, (params));
        dealEverybody(1 * 1e18);
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: user,
            spender: address(zapper),
            value: _vault.balanceOf(user),
            nonce: 0,
            deadline: block.timestamp + 1 days
        });
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            address(zapper), permit.value, permit.nonce, permit.deadline
        );

        PermitParams memory permitParams = PermitParams({
            value: permit.value,
            deadline: block.timestamp + 1 days,
            v: v,
            r: r,
            s: s
        });

        //execPermit(user, address(zapper), address(_vault), permitParams);

        uint256 beforeWith = (IERC20(address(_vault)).balanceOf(user));
        uint256 beforeZap = (IERC20(address(params.tokenOut)).balanceOf(user));

        if (keccak256(swapData) == keccak256(hex"")) vm.expectRevert();
        zapper.withdrawAndZapWithPermit(
            _vault, params.router, params.amount, swapData, permitParams
        );

        uint256 afterWith = (IERC20(address(_vault)).balanceOf(user));
        uint256 afterZap = (IERC20(address(params.tokenOut)).balanceOf(user));

        if (keccak256(swapData) != keccak256(hex"")) {
            assertTrue(beforeWith > afterWith, "Deposit permit failed");
            assertTrue(
                beforeZap < afterZap,
                "Deposit permit failed because no token received"
            );
        }
    }

    function _redeemAndZapPermit(Swap memory params) public {
        ERC20Permit shareToken = ERC20Permit(address(_vault));
        _vault.approve(address(zapper), type(uint256).max);
        sigUtils = new SigUtils(shareToken.DOMAIN_SEPARATOR());
        bytes memory swapData = _getSwapData(address(zapper), user, params);
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: user,
            spender: address(zapper),
            value: _vault.balanceOf(user),
            nonce: 0,
            deadline: block.timestamp + 1 days
        });
        (uint8 v, bytes32 r, bytes32 s) = _signPermit(
            address(zapper), permit.value, permit.nonce, permit.deadline
        );

        PermitParams memory permitParams = PermitParams({
            value: permit.value,
            deadline: block.timestamp + 1 days,
            v: v,
            r: r,
            s: s
        });

        //execPermit(user, address(zapper), address(_vault), permitParams);

        uint256 beforeRedeem = (IERC20(address(_vault)).balanceOf(user));
        uint256 beforeZap = IERC20(address(params.tokenOut)).balanceOf(user);
        console.log("Shares balance before redeem", beforeRedeem);
        console.log("Zapped balance before redeem", beforeZap);

        uint256 sharesBalance = _vault.balanceOf(user);
        
        if (keccak256(swapData) == keccak256(hex"")) vm.expectRevert();
        zapper.redeemAndZapWithPermit(
            _vault,
            params.router,
            sharesBalance,
            swapData,
            permitParams
        );

        uint256 afterRedeem = (IERC20(address(_vault)).balanceOf(user));
        uint256 afterZap = IERC20(address(params.tokenOut)).balanceOf(user);
        console.log("Shares balance after redeem", afterRedeem);
        console.log("Zapped balance after redeem", afterZap);

        if (keccak256(swapData) != keccak256(hex"")) {
            assertTrue(beforeRedeem > afterRedeem, "Deposit permit failed");
            assertTrue(
                beforeZap < afterZap,
                "Deposit permit failed because no token received"
            );
        }
    }

    function execPermit(
        address owner,
        address spender,
        address token,
        PermitParams memory permitParams
    ) internal {
        ERC20Permit(address(token)).permit(
            owner,
            spender,
            permitParams.value,
            permitParams.deadline,
            permitParams.v,
            permitParams.r,
            permitParams.s
        );
    }

    function _signPermit(
        address _spender,
        uint256 _value,
        uint256 _nonce,
        uint256 deadline
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: user,
            spender: _spender,
            value: _value,
            nonce: _nonce,
            deadline: deadline
        });
        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (v, r, s) = vm.sign(userPrivateKey, digest);
        return (v, r, s);
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
}
