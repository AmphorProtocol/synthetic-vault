//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library Constants {
    bytes32 internal constant USDC_TICKER = "usdc";
    bytes32 internal constant USDT_TICKER = "usdt";
    bytes32 internal constant DAI_TICKER = "dai";
    bytes32 internal constant CRV_TICKER = "a3CRV";

    uint256 internal constant CVX_LUSD_PID = 33;
    uint256 internal constant CVX_MIM_PID = 40;
    uint256 internal constant CVX_FRAX_LUSD_PID = 102;
    uint256 internal constant CVX_EURT_POLYGON_PID = 5;
    uint256 internal constant CVX_USDR_POLYGON_PID = 11;

    uint256 internal constant TRADE_DEADLINE = 2000;

    address internal constant FRAX_USDC_ADDRESS =
        0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2;
    address internal constant FRAX_USDC_LP_ADDRESS =
        0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC;
    address internal constant CRV_FRAX_LUSD_ADDRESS =
        0x497CE58F34605B9944E6b15EcafE6b001206fd25;
    address internal constant CRV_FRAX_LUSD_LP_ADDRESS =
        0x497CE58F34605B9944E6b15EcafE6b001206fd25;
    address internal constant CVX_FRAX_LUSD_REWARDS_ADDRESS =
        0x053e1dad223A206e6BCa24C77786bb69a10e427d;
    address internal constant CVX_ADDRESS =
        0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address internal constant CRV_ADDRESS =
        0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDC_ADDRESS_POLYGON =
        0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address internal constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant DAI_ADDRESS =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant WETH_ADDRESS =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant WETH_ADDRESS_POLYGON =
        0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address internal constant LUSD_ADDRESS =
        0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address internal constant MIM_ADDRESS =
        0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;

    address internal constant EURT_POLYGON_ADDRESS =
        0x7BDF330f423Ea880FF95fC41A280fD5eCFD3D09f;
    address internal constant USDR_POLYGON_ADDRESS =
        0xb5DFABd7fF7F83BAB83995E72A52B97ABb7bcf63;

    address internal constant SUSHI_ROUTER_ADDRESS =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address internal constant SUSHI_CRV_WETH_ADDRESS =
        0x58Dc5a51fE44589BEb22E8CE67720B5BC5378009;
    address internal constant SUSHI_WETH_CVX_ADDRESS =
        0x05767d9EF41dC40689678fFca0608878fb3dE906;
    address internal constant SUSHI_WETH_USDT_ADDRESS =
        0x06da0fd433C1A5d7a4faa01111c044910A184553;

    address internal constant CVX_BOOSTER_ADDRESS =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address internal constant CRV_3POOL_ADDRESS =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address internal constant CRV_3POOL_LP_ADDRESS =
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    address internal constant CVX_BOOSTER_POLYGON_ADDRESS =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address internal constant CRV_3POOL_POLYGON_ADDRESS =
        0xa138341185a9D0429B0021A11FB717B225e13e1F;
    address internal constant CRV_3POOL_LP_POLYGON_ADDRESS =
        0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171;

    address internal constant CRV_LUSD_ADDRESS =
        0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address internal constant CRV_LUSD_LP_ADDRESS =
        0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address internal constant CVX_LUSD_REWARDS_ADDRESS =
        0x2ad92A7aE036a038ff02B96c88de868ddf3f8190;

    address internal constant CRV_EURT_POLYGON_ADDRESS =
        0x600743B1d8A96438bD46836fD34977a00293f6Aa;
    address internal constant CRV_EURT_LP_POLYGON_ADDRESS =
        0x600743B1d8A96438bD46836fD34977a00293f6Aa;
    address internal constant CRV_EURT_POLYGON_REWARDS_ADDRESS =
        0xc501491b0e4A73B2eFBaC564a412a927D2fc83dD;

    address internal constant CRV_USDR_POLYGON_ADDRESS =
        0xa138341185a9D0429B0021A11FB717B225e13e1F;
    address internal constant CRV_USDR_LP_POLYGON_ADDRESS =
        0xa138341185a9D0429B0021A11FB717B225e13e1F;
    address internal constant CRV_USDR_POLYGON_REWARDS_ADDRESS =
        0x3D17b2BcfcD7E0Dc4d6a0d6bA67c29FBc592B323;

    address internal constant CRV_MIM_ADDRESS =
        0x5a6A4D54456819380173272A5E8E9B9904BdF41B;
    address internal constant CRV_MIM_LP_ADDRESS =
        0x5a6A4D54456819380173272A5E8E9B9904BdF41B;
    address internal constant CVX_MIM_REWARDS_ADDRESS =
        0xFd5AbF66b003881b88567EB9Ed9c651F14Dc4771;
    address internal constant CVX_MIM_EXTRA_ADDRESS =
        0x69a92f1656cd2e193797546cFe2EaF32EACcf6f7;
    address internal constant MIM_EXTRA_ADDRESS =
        0x090185f2135308BaD17527004364eBcC2D37e5F6;
    address internal constant MIM_EXTRA_PAIR_ADDRESS =
        0xb5De0C3753b6E1B4dBA616Db82767F17513E6d4E;

    address internal constant SDT_MIM_VAULT_ADDRESS =
        0x98dd95D0ac5b70B0F4ae5080a1C2EeA8c5c48387;
    address internal constant SDT_MIM_SPELL_ADDRESS =
        0x090185f2135308BaD17527004364eBcC2D37e5F6;
}
