// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

contract AddLiquidity is Script {
    address constant TOKENA = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // UNI
    address constant TOKENB = 0x6c64E8278B7d5513143D59Bf1484B0e6972e4505; // JSN

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address swapContractAddr = vm.envAddress("SWAP_CONTRACT");

        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);
        vm.startBroadcast(pk);

        uint256 amountA = 0.0002 ether; // 1e14
        uint256 amountB;

        bool isFirstLiquidity = swapContract.isFirstLiquidity(TOKENA, TOKENB);

        if (isFirstLiquidity) {
            amountB = 1000 ether;
        } else {
            amountB = swapContract.getPairRatioAmount(TOKENA, TOKENB, amountA);
        }

        console.log(amountB);

        // Approve
        IERC20(TOKENA).approve(swapContractAddr, amountA);
        IERC20(TOKENB).approve(swapContractAddr, amountB);

        // Add Liquidity
        uint256 liquidity = swapContract.addLiquidity(TOKENA, TOKENB, amountA, amountB);
        console.log("Liquidity tokens received:", liquidity);

        vm.stopBroadcast();
    }
}
