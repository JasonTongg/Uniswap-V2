// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

contract RemoveLiquidity is Script {
    // UNI Token (Sepolia)
    address constant TOKENA = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    // Your JSN token
    address constant TOKENB = 0x0E1Efea9F52f99bAAC1ca663D41119C037258D54;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address swapContractAddr = vm.envAddress("SWAP_CONTRACT");

        address user = vm.addr(pk); // ✅ your wallet address
        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);

        vm.startBroadcast(pk);

        // Get pair contract
        address pair = swapContract.factory().getPair(TOKENA, TOKENB);
        require(pair != address(0), "PAIR DOES NOT EXIST");
        console.log("PAIR:", pair);

        // ✅ LP Token balance belongs to `user`
        uint256 liquidity = IUniswapV2Pair(pair).balanceOf(user);
        require(liquidity > 0, "NO LP TOKENS TO REMOVE");
        console.log("User LP Balance:", liquidity);

        // Remove only half (optional)
        uint256 removeAmount = liquidity;
        console.log("Removing LP:", removeAmount);

        // Approve swap contract to spend LP tokens
        IUniswapV2Pair(pair).approve(swapContractAddr, removeAmount);

        // Call removeLiquidity
        (uint256 amountA, uint256 amountB) = swapContract.removeLiquidity(TOKENA, TOKENB, removeAmount);

        console.log("Received UNI:", amountA);
        console.log("Received JSN:", amountB);

        vm.stopBroadcast();
    }
}
