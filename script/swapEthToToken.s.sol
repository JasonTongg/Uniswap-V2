// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol"; // <-- to log values
import "../src/uniswapv2.sol";

contract SwapSepoliaScript is Script {
    // Token you want to buy (UNI on Sepolia)
    address constant TOKEN_OUT = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        address payable swapContractAddr = payable(vm.envAddress("SWAP_CONTRACT"));
        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);

        uint256 amountETH = 0.05 ether;

        uint256 expectedUNI = swapContract.getPriceETHtoToken(TOKEN_OUT, amountETH);

        vm.startBroadcast(pk);

        swapContract.swapETHForToken{value: amountETH}(TOKEN_OUT);

        vm.stopBroadcast();
    }
}
