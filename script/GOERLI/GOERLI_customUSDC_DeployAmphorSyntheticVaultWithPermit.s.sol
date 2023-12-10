// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {
    AmphorSyntheticVaultWithPermit,
    ERC20,
    IERC20
} from "../../src/AmphorSyntheticVaultWithPermit.sol";

contract GOERLI_customUSDC_DeployAmphorSyntheticVaultWithPermit is Script {
    function run() external {
        // if you want to deploy a vault with a seed phrase instead of a pk, uncomment the following line
        // string memory seedPhrase = vm.readFile(".secret");
        // uint256 privateKey = vm.deriveKey(seedPhrase, 0);
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address amphorlabsAddress = vm.envAddress("AMPHORLABS_ADDRESS_GOERLI");
        ERC20 underlying = ERC20(vm.envAddress("CUSTOM_USDC_GOERLI"));
        uint8 decimalOffset = uint8(vm.envUint("DECIMALS_OFFSET_USDC"));
        uint16 fees = uint16(vm.envUint("INITIAL_FEES_AMOUNT"));
        uint256 bootstrapAmount = vm.envUint("BOOTSTRAP_AMOUNT_SYNTHETIC_USDC");
        string memory vaultName = vm.envString("SYNTHETIC_USDC_V0_NAME");
        string memory vaultSymbol = vm.envString("SYNTHETIC_USDC_V0_SYMBOL");

        vm.startBroadcast(privateKey);

        AmphorSyntheticVaultWithPermit amphorSyntheticVault =
        new AmphorSyntheticVaultWithPermit(
                underlying,
                vaultName,
                vaultSymbol,
                decimalOffset
            );

        amphorSyntheticVault.setFees(fees);

        IERC20(underlying).approve(
            address(amphorSyntheticVault), bootstrapAmount
        );
        amphorSyntheticVault.deposit(bootstrapAmount, amphorlabsAddress);

        amphorSyntheticVault.transferOwnership(amphorlabsAddress);

        console.log(
            "Synthetic vault USDC contract address: ",
            address(amphorSyntheticVault)
        );

        vm.stopBroadcast();
    }
}
