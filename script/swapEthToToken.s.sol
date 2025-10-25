// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol"; // <-- to log values
import "../src/uniswapv2.sol";

contract SwapSepoliaScript is Script {
    // Token you want to buy (UNI on Sepolia)
    address constant TOKEN_OUT = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        address swapContractAddr = vm.envAddress("SWAP_CONTRACT");
        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);

        uint256 amountETH = 0.01 ether;

        uint256 expectedUNI = swapContract.getPriceETHtoToken(TOKEN_OUT, amountETH);
        console.log("If you swap", amountETH / 1e18, "ETH you will receive approx:", expectedUNI);

        vm.startBroadcast(pk);

        swapContract.swapETHForToken{value: amountETH}(TOKEN_OUT);

        vm.stopBroadcast();
    }
}
