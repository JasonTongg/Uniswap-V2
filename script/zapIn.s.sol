// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

contract AddLiquidity is Script {
    address constant TOKENA = 0x6c64E8278B7d5513143D59Bf1484B0e6972e4505; // WETH
    address constant TOKENB = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // JSN

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address payable swapContractAddr = payable(vm.envAddress("SWAP_CONTRACT"));

        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);
        vm.startBroadcast(pk);

        uint256 amountA = 100 ether;

        IERC20(TOKENA).approve(swapContractAddr, amountA);
        IERC20(TOKENB).approve(swapContractAddr, amountA);

        uint256 liquidity = swapContract.zapIn(TOKENA, TOKENA, TOKENB, amountA);

        vm.stopBroadcast();
    }
}
