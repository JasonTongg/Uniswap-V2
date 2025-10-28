// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

contract RemoveLiquidityETH is Script {
    address constant TOKEN = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address payable swapContractAddr = payable(vm.envAddress("SWAP_CONTRACT"));

        address user = vm.addr(pk);
        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);

        vm.startBroadcast(pk);

        address weth = swapContract.router().WETH();
        address pair = swapContract.factory().getPair(TOKEN, weth);
        uint256 liquidity = IUniswapV2Pair(pair).balanceOf(user);

        uint256 removeAmount = liquidity;
        console.log("Removing LP:", removeAmount);

        IUniswapV2Pair(pair).approve(swapContractAddr, removeAmount);

        (uint256 amountETH) = swapContract.zapOutEth(TOKEN, removeAmount);

        console.log("Received ETH:", amountETH);

        vm.stopBroadcast();
    }
}
