// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface ISwap {
    function setSlippageBP(uint256 newSlippageBasisPoints) external;
}

contract SetSlippage is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address payable swapContractAddr = payable(0x9D4eB64290887536CaBc9B9E841132145EE55F07);

        vm.startBroadcast(pk);

        // Set 10% slippage (1000 basis points)
        ISwap(swapContractAddr).setSlippageBP(9000);

        console.log("Slippage updated to 10% (1000 BP)");

        vm.stopBroadcast();
    }
}
