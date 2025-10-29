pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/token.sol";

contract DeployTokenSwap is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        new MyERC20(
            0xeFF3521fb13228C767Ad6Dc3b934F9eFAC9c56aD,
            0xeFF3521fb13228C767Ad6Dc3b934F9eFAC9c56aD,
            "JASON",
            "JSN",
            1000000
        );

        vm.stopBroadcast();
    }
}
