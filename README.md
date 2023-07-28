## Context
`Amphor` protocol is a `L1 DeFi` protocol proposing `ERC-4626` based strategies.
The first startegy to come out is a timelocked strategy that require the funds
to exit the vault during the product duration (which varies from `2` to
`6` weeks).  

## AmphorSyntheticVault
This vault is the most basic strategy on the code side because the funds are
deposited by the users, then the vault is locked during the product period. Once
it has been locked, the funds go to a market maker wallet that is keeping the
assets in garantee.  
At the end of the period (which varies from `2` to `6` weeks), `Amphor`
get back the funds into the vault and users can `deposit` and/or `withdraw`
again.

## Underlying supported
For the first iteration of the protocol, the only underlying supported will be
`USDC` from `Circle`. 
In the future, we might support `WBTC` and `WETH` as underlying assets.
Since `USDC` token supports `Permit` operations but not `WBTC` and `WETH`, we
have separated this feature into another contract (`AmphorSyntheticVaultWithPermit`).

## Process flow on the vault manager side
`NOTE:` Management of the vault is handled by a multisig wallet.  
1. The vault contract is deployed (`constructor`) and some funds are directly
deposited into it in order to bootstrap it and prevent as much as possible from
inflation attacks (event if there are others protections from it).
A performance fee of `20.00%` for `Amphor` protocol is set.
2. The vault is open for `deposit` and `withdraw` during a little period (approx
2 days).
3. The vault is locked (`deposit`/`withdraw` shouldn't be possible) with the
`start` function (callable only by `owner`/manager of the vault). During this
transaction the funds are withdrawn from the contract.
4. After the product period end, the vault is unlocked (`deposit`/`withdraw`
are now be possible) using
the `end` function (callable only by the `owner` of the vault).
In case of a positive performance, some fees are taken fees by the protocol
(that cannot exceed `30.00%` and can only be changed by `owner` of the vault).

## Main contracts
### Protocol contracts files
- `AmphorSyntheticVault.sol`: Vanilla `AmphorSyntheticVault`.
- `AmphorSyntheticVaultWithPermit.sol`: `AmphorSyntheticVault` with `Permit` feature.
___
### Deployment contracts files
- `L1_USDC_DeployAmphorSyntheticVault.sol`: Deployment script for `AmphorSyntheticVaultWithPermit`
with `USDC` as underlying. Should bootstrap the vault with `100 USDC` (based on
the `env` file). Should set the perf fees to `20.00%`.  
- `L1_WBTC_DeployAmphorSyntheticVault.sol`: Deployment script for `AmphorSyntheticVault`
with `WBTC` as underlying. Should bootstrap the vault with `0.01 WBTC` (based on
the `env` file). Should set the perf fees to `20.00%`.  
- `L1_WETH_DeployAmphorSyntheticVault.sol`: Deployment script for `AmphorSyntheticVault`
with `WETH` as underlying. Should bootstrap the vault with `0.1 WETH` (based on
the `env` file). Should set the perf fees to `20.00%`.  
___
### Test contracts files
- `a16zCompliance.t.sol`: Implements the tests of `a16z`. Unfortunaly we didn't
manage to make them work.
- `cryticCompliance.t.sol`: Implements the tests of `crytic` (from
[Trail of a bits](https://www.trailofbits.com/)). These one pass, you can launch
them with the following command:
```
$ echidna . --contract CryticERC4626PropertyTestsSynth --config test/echidna.config.yaml
```
- `SyntheticBase.t.sol`: Should define a part of the main state variables. Should 
define some functions that will be directly used into the actual tests.
- `SyntheticBasic.t.sol`: Should implement some basics tests that test the vault
state variables and some basic properties of the vault.
- `SyntheticDepositAndWithdraw.t.sol`: Should implement some tests on the deposit
and the withdraw function.
- `SyntheticEndAndStart.t.sol`: Should implement some tests on the start and the
end function.
- `SyntheticInflation.t.sol`: Should implement some tests demonstrating vault
resilience in the face of inflationary attacks.
- `SyntheticPausable.t.sol`: Should implement some tests demonstrating the good
working of the `Pausable` feature.
- `SyntheticPermit.t.sol`: Should implement some tests demonstrating the good
working of the `Permit` feature.
- `SigUtils.sol`: Should implement utils functions used by `SyntheticPermit`
contract test (`SyntheticPermit.t.sol`).
## Useful commands
### Foundry
The protocol is a [Foundry](https://book.getfoundry.sh) project.
[Foundry](https://book.getfoundry.sh) a blazing fast, portable and modular
toolkit for Ethereum application development written in Rust.
#### Foundry commands
##### Build
```shell
$ forge build
```
##### Test
```shell
$ forge test
```
##### Format
```shell
$ forge fmt
```
##### Coverage
```shell
$ forge coverage
```
##### Gas Snapshots
```shell
$ forge snapshot
```
##### Anvil
```shell
$ anvil
```
##### Deploy
```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```
##### Cast
```shell
$ cast <subcommand>
```
##### Help
```shell
$ forge --help
$ anvil --help
$ cast --help
```
___
