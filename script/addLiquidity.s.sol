// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

contract AddLiquidity is Script {
    address constant TOKENA = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // UNI
    address constant TOKENB = 0x0E1Efea9F52f99bAAC1ca663D41119C037258D54; // JSN

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address swapContractAddr = vm.envAddress("SWAP_CONTRACT");

        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);
        vm.startBroadcast(pk);

        uint256 amountA = 0.0001 ether; // 1e14

        // Ambil pair
        address pair = swapContract.factory().getPair(TOKENA, TOKENB);
        require(pair != address(0), "PAIR NOT FOUND");

        // Cek urutan token di pair
        address token0 = IUniswapV2Pair(pair).token0();
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();

        uint reserveA;
        uint reserveB;

        if (token0 == TOKENA) {
            reserveA = reserve0;
            reserveB = reserve1;
        } else {
            reserveA = reserve1;
            reserveB = reserve0;
        }

        // Hitung amountB sesuai harga pool
        uint256 amountB = (amountA * reserveB) / reserveA;

        console.log("Calculated amountB required:", amountB);

        // Approve
        IERC20(TOKENA).approve(swapContractAddr, amountA);
        IERC20(TOKENB).approve(swapContractAddr, amountB);

        // Add Liquidity
        uint liquidity = swapContract.addLiquidity(TOKENA, TOKENB, amountA, amountB);
        console.log("Liquidity tokens received:", liquidity);

        vm.stopBroadcast();
    }
}
