// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

contract AddLiquidityETH is Script {
    address constant TOKEN = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // UNI

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address payable swapContractAddr = payable(vm.envAddress("SWAP_CONTRACT"));

        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);
        vm.startBroadcast(pk);

        uint256 amountToken = 0.006 ether;
        uint256 amountETH;

        bool isFirstLiquidity = swapContract.isFirstLiquidity(TOKEN, swapContract.router().WETH());

        if (isFirstLiquidity) {
            amountETH = 0.0005 ether;
        } else {
            amountETH = swapContract.getPairRatioAmount(TOKEN, swapContract.router().WETH(), amountToken, TOKEN);
        }

        console.log(amountETH);

        IERC20(TOKEN).approve(swapContractAddr, amountToken);

        uint256 liquidity = swapContract.addLiquidityETH{value: amountETH}(TOKEN, amountToken);

        console.log("Liquidity Provided:", liquidity);
        vm.stopBroadcast();
    }
}
