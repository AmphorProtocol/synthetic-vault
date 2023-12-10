// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {VaultZapper} from "../../src/VaultZapper.sol";
import "@openzeppelin-v4.9.3/contracts/token/ERC20/ERC20.sol";
import {AmphorSyntheticVaultWithPermit} from
    "../../src/AmphorSyntheticVaultWithPermit.sol";
import {IERC4626} from "@openzeppelin-v4.9.3/contracts/interfaces/IERC4626.sol";

contract L1_VaultZapper is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address amphorlabsAddress = vm.envAddress("AMPHORLABS_ADDRESS");
        IERC4626 vault = IERC4626(0x2791EB5807D69Fe10C02eED6B4DC12baC0701744);
        address _router = 0x1111111254EEB25477B68fb85Ed929f73A960582;
        ERC20 _DAI = ERC20(vm.envAddress("DAI_MAINNET"));
        ERC20 _USDC = ERC20(vm.envAddress("USDC_MAINNET"));
        ERC20 _USDT = ERC20(vm.envAddress("USDT_MAINNET"));
        ERC20 _WETH = ERC20(vm.envAddress("WETH_MAINNET"));
        ERC20 _STETH = ERC20(vm.envAddress("STETH_MAINNET"));
        ERC20 _WBTC = ERC20(vm.envAddress("WBTC_MAINNET"));

        vm.startBroadcast(privateKey);

        VaultZapper zapper =
            VaultZapper(0xd697D2af3ddfe4Ed24e92A230C4B93606B5d05fB);
        zapper.toggleRouterAuthorization(_router);

        zapper.approveTokenForRouter(_DAI, _router);
        zapper.approveTokenForRouter(_USDC, _router);
        zapper.approveTokenForRouter(_USDT, _router);
        zapper.approveTokenForRouter(_WETH, _router);
        zapper.approveTokenForRouter(_STETH, _router);
        zapper.approveTokenForRouter(_WBTC, _router);

        zapper.toggleVaultAuthorization(IERC4626(address(vault)));

        zapper.transferOwnership(amphorlabsAddress);

        console.log("Zapper contract address: ", address(zapper));

        vm.stopBroadcast();
    }
}
