// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/uniswapv2.sol";

interface IERC20Minimal {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SwapUniToEth is Script {
    address constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        address payable swapContractAddr = payable(vm.envAddress("SWAP_CONTRACT"));
        TokenSwapContract swapContract = TokenSwapContract(swapContractAddr);

        vm.startBroadcast(pk);

        address user = vm.addr(pk);

        uint256 uniBalance = IERC20Minimal(UNI).balanceOf(user);
        require(uniBalance > 0, "No UNI to swap");

        uint256 expectedETH = swapContract.getPriceTokenToETH(UNI, uniBalance);

        IERC20Minimal(UNI).approve(address(swapContract), uniBalance);

        swapContract.swapTokenForETH(UNI, uniBalance);

        vm.stopBroadcast();
    }
}
