// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

contract AddLiquidity is Script {
    address constant TOKENA = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14; // WETH
    address constant TOKENB = 0x6c64E8278B7d5513143D59Bf1484B0e6972e4505; // JSN

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address swapContractAddr = vm.envAddress("SWAP_CONTRACT");

        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);
        vm.startBroadcast(pk);

        uint256 amountA = 0.0002 ether;

        // Approve
        IERC20(TOKENA).approve(swapContractAddr, amountA);

        // Add Liquidity
        uint256 liquidity = swapContract.zapIn(TOKENA, TOKENA, TOKENB, amountA);
        console.log("Liquidity tokens received:", liquidity);

        vm.stopBroadcast();
    }
}
