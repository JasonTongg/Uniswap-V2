// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

contract RemoveLiquidityETH is Script {
    // Your JSN Token
    address constant TOKEN = 0x6c64E8278B7d5513143D59Bf1484B0e6972e4505;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address swapContractAddr = vm.envAddress("SWAP_CONTRACT");

        address user = vm.addr(pk);
        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);

        vm.startBroadcast(pk);

        // Get WETH address to identify ETH pair
        address weth = swapContract.router().WETH();

        // Find pair of JSN <-> WETH
        address pair = swapContract.factory().getPair(TOKEN, weth);
        require(pair != address(0), "PAIR DOES NOT EXIST");
        console.log("PAIR:", pair);

        // Read LP token balance
        uint256 liquidity = IUniswapV2Pair(pair).balanceOf(user);
        require(liquidity > 0, "NO LP TOKENS TO REMOVE");
        console.log("User LP Balance:", liquidity);

        // Remove only half (optional)
        uint256 removeAmount = liquidity;
        console.log("Removing LP:", removeAmount);

        // Approve contract to spend LP tokens
        IUniswapV2Pair(pair).approve(swapContractAddr, removeAmount);

        // Remove liquidity -> returns JSN and ETH
        (uint256 amountToken, uint256 amountETH) = swapContract.removeLiquidityETH(TOKEN, removeAmount);

        console.log("Received JSN:", amountToken);
        console.log("Received ETH:", amountETH);

        vm.stopBroadcast();
    }
}
