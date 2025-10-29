// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

contract RemoveLiquidity is Script {
    address constant TOKENA = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address constant TOKENB = 0x0E1Efea9F52f99bAAC1ca663D41119C037258D54;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address payable swapContractAddr = payable(vm.envAddress("SWAP_CONTRACT"));

        address user = vm.addr(pk);
        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);

        vm.startBroadcast(pk);

        address pair = swapContract.factory().getPair(TOKENA, TOKENB);
        uint256 liquidity = IUniswapV2Pair(pair).balanceOf(user);

        uint256 removeAmount = liquidity;

        IUniswapV2Pair(pair).approve(swapContractAddr, removeAmount);

        (uint256 amountA, uint256 amountB) = swapContract.removeLiquidity(TOKENA, TOKENB, removeAmount);

        vm.stopBroadcast();
    }
}
