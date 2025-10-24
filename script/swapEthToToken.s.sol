// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol"; // <-- to log values
import "../src/uniswapv2.sol";

contract SwapSepoliaScript is Script {
    // Your deployed swap contract
    TokenSwapContract public swapContract = TokenSwapContract(0x5deB5E322dA6ec413363Aef0399F3A5d24C8c1cB);

    // Token you want to buy (UNI on Sepolia)
    address constant TOKEN_OUT = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        uint256 amountETH = 0.01 ether;

        // 1) Preview price before swapping
        uint256 expectedUNI = swapContract.getPriceETHtoToken(TOKEN_OUT, amountETH);
        console.log("If you swap", amountETH / 1e18, "ETH you will receive approx:", expectedUNI);

        // 2) Execute swap
        vm.startBroadcast(pk);

        swapContract.swapETHForToken{value: amountETH}(TOKEN_OUT);

        vm.stopBroadcast();
    }
}
