// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

contract AddLiquidityETH is Script {
    address constant TOKEN = 0x0E1Efea9F52f99bAAC1ca663D41119C037258D54; // JSN

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address swapContractAddr = vm.envAddress("SWAP_CONTRACT");

        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);
        vm.startBroadcast(pk);

        uint256 amountToken = 5000 ether;
        uint256 amountETH = 0.005 ether;

        IERC20(TOKEN).approve(swapContractAddr, amountToken);

        uint liquidity = swapContract.addLiquidityETH{value: amountETH}(
            TOKEN,
            amountToken
        );

        console.log("Liquidity Provided:", liquidity);
        vm.stopBroadcast();
    }
}
