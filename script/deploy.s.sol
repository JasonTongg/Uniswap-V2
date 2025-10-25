pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/uniswapv2.sol";

contract DeployTokenSwap is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        new TokenSwapContract(
            0xF62c03E08ada871A0bEb309762E260a7a6a880E6,
            0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3
        );

        vm.stopBroadcast();
    }
}
