// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

contract AddLiquidityETH is Script {
    address constant TOKEN = 0x6c64E8278B7d5513143D59Bf1484B0e6972e4505; // JSN

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address swapContractAddr = vm.envAddress("SWAP_CONTRACT");

        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);
        vm.startBroadcast(pk);

        uint256 amountToken = 7000 ether;
        uint256 amountETH;

        bool isFirstLiquidity = swapContract.isFirstLiquidity(TOKEN, swapContract.router().WETH());

        if (isFirstLiquidity) {
            amountETH = 0.0005 ether;
        } else {
            amountETH = swapContract.getPairRatioAmount(TOKEN, swapContract.router().WETH(), amountToken);
        }

        console.log(amountETH);

        IERC20(TOKEN).approve(swapContractAddr, amountToken);

        uint256 liquidity = swapContract.addLiquidityETH{value: amountETH}(TOKEN, amountToken);

        console.log("Liquidity Provided:", liquidity);
        vm.stopBroadcast();
    }
}
