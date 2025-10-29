// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyERC20 is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    constructor(
        address _recipient,
        address _initialOwner,
        string memory _name,
        string memory _symbol,
        uint256 _initialTotalSupply
    ) ERC20(_name, _symbol) Ownable(_initialOwner) ERC20Permit(_name) {
        _mint(_recipient, _initialTotalSupply * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
