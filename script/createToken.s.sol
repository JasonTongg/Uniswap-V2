// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/TokenFactory.sol";
import "../src/token.sol";

contract TokenFactoryScript is Script {
    function run() external {
        address factoryAddress = vm.envAddress("FACTORY_CONTRACT");
        TokenFactory factory = TokenFactory(factoryAddress);

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        string memory name = "MyNewToken";
        string memory symbol = "MNT";
        uint256 totalSupply = 1_000_000;

        address tokenAddr = factory.createToken(name, symbol, totalSupply);
        console.log("New token deployed at:", tokenAddr);

        address[] memory tokens = factory.getAllTokens();
        console.log("All tokens count:", tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            console.log(tokens[i]);
        }

        vm.stopBroadcast();
    }
}
