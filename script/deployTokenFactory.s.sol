pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/tokenFactory.sol";

contract DeployTokenFactory is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        new TokenFactory();

        vm.stopBroadcast();
    }
}
