// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

contract AddLiquidity is Script {
    address constant TOKENA = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // UNI
    address constant TOKENB = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; // JSN

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address payable swapContractAddr = payable(vm.envAddress("SWAP_CONTRACT"));

        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);
        vm.startBroadcast(pk);

        uint256 amountA = 0.0002 ether;
        uint256 amountB;

        bool isFirstLiquidity = swapContract.isFirstLiquidity(TOKENA, TOKENB);

        if (isFirstLiquidity) {
            amountB = 1000 ether;
        } else {
            amountB = swapContract.getPairRatioAmount(TOKENA, TOKENB, amountA, TOKENA);
        }

        IERC20(TOKENA).approve(swapContractAddr, amountA);
        IERC20(TOKENB).approve(swapContractAddr, amountB);

        uint256 liquidity = swapContract.addLiquidity(TOKENA, TOKENB, amountA, amountB);

        vm.stopBroadcast();
    }
}
