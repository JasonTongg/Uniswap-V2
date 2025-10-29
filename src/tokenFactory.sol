// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./token.sol";

contract TokenFactory {
    event TokenCreated(address indexed creator, address tokenAddress, string name, string symbol, uint256 totalSupply);

    address[] public allTokens;

    function createToken(string memory name, string memory symbol, uint256 totalSupply)
        external
        returns (address tokenAddress)
    {
        MyERC20 token = new MyERC20(msg.sender, msg.sender, name, symbol, totalSupply);

        tokenAddress = address(token);

        allTokens.push(tokenAddress);

        emit TokenCreated(msg.sender, tokenAddress, name, symbol, totalSupply);
    }

    function getAllTokens() external view returns (address[] memory) {
        return allTokens;
    }
}
