// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TokenFactory.sol";
import "../src/token.sol";

contract TokenFactoryTest is Test {
    TokenFactory factory;
    address user = address(0x123);

    function setUp() public {
        factory = new TokenFactory();
        vm.deal(user, 100 ether);
    }

    function testCreateToken() public {
        vm.startPrank(user);

        string memory name = "ChatGPT Token";
        string memory symbol = "CGT";
        uint256 totalSupply = 1_000_000;

        address tokenAddr = factory.createToken(name, symbol, totalSupply);
        MyERC20 token = MyERC20(tokenAddr);

        assertEq(factory.allTokens(0), tokenAddr);
        assertEq(factory.getAllTokens().length, 1);

        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);

        assertEq(token.balanceOf(user), totalSupply * 10 ** token.decimals());

        vm.stopPrank();
    }

    function testGetAllTokens() public {
        vm.startPrank(user);

        factory.createToken("A", "A", 100);
        factory.createToken("B", "B", 200);

        vm.stopPrank();

        address[] memory tokens = factory.getAllTokens();

        assertEq(tokens.length, 2);
    }

    function testEmitTokenCreatedEvent() public {
        vm.startPrank(user);

        vm.expectEmit(true, true, true, false);
        emit TokenFactory.TokenCreated(user, address(0), "Test", "TST", 500);

        factory.createToken("Test", "TST", 500);

        vm.stopPrank();
    }
}
