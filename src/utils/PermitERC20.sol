// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@solmate/tokens/ERC20.sol";

contract PermitERC20 is ERC20 {
    constructor(string memory _name, string memory _symbol, uint8 _decimals)
        ERC20(_name, _symbol, _decimals)
    {
        _mint(msg.sender, 10000 * 10 ** 6);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
