// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/uniswapv2.sol";
import {JasonToken} from "../src/token.sol";

interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}

contract TokenSwapTest is Test {
    // --- CONFIG ---
    string SEPOLIA_RPC = "sepolia";
    uint256 mainnetFork;

    // Router + Factory addresses on Sepolia (Uniswap V2 forks)
    address constant UNISWAP_FACTORY = 0xF62c03E08ada871A0bEb309762E260a7a6a880E6;
    address constant UNISWAP_ROUTER = 0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3;

    // Example ERC20 tokens (check that they exist on Sepolia)
    address constant TOKEN_WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14; // example: WETH
    address constant TOKEN_UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // example: UNI
    address constant TOKEN_JSN = 0x6c64E8278B7d5513143D59Bf1484B0e6972e4505; // example: JSN

    TokenSwapContract swapContract;

    address user = address(0xeFF3521fb13228C767Ad6Dc3b934F9eFAC9c56aD);

    function setUp() public {
        // Fork Sepolia
        mainnetFork = vm.createFork(vm.envString("SEPOLIA_RPC_URL"));
        vm.selectFork(mainnetFork);

        // Deploy contract
        swapContract = new TokenSwapContract(UNISWAP_FACTORY, UNISWAP_ROUTER);

        // Label addresses for clarity
        vm.label(user, "User");
        vm.label(address(swapContract), "TokenSwapContract");
    }

    function testSwapTokenToToken() public {
        vm.startPrank(user);

        uint256 amountIn = 7e13;

        uint256 balA = IERC20(TOKEN_JSN).balanceOf(user);
        uint256 balB = IERC20(TOKEN_UNI).balanceOf(user);

        IERC20(TOKEN_UNI).approve(address(swapContract), amountIn);

        uint256 amountOut = swapContract.swapToken(TOKEN_UNI, TOKEN_JSN, amountIn);

        uint256 tokenABalanceAfter = IERC20(TOKEN_JSN).balanceOf(user);
        uint256 tokenBBalanceAfter = IERC20(TOKEN_UNI).balanceOf(user);

        assertEq(tokenABalanceAfter, balA + amountOut, "Token A balance incorrect after swap");
        assertEq(tokenBBalanceAfter, balB - amountIn, "Token B balance incorrect after swap");

        vm.stopPrank();
    }

    function testSwapTokenToEth() public {
        vm.startPrank(user);

        uint256 amountIn = 5e15;

        uint256 balB = IERC20(TOKEN_UNI).balanceOf(user);
        uint256 balA = user.balance;

        IERC20(TOKEN_UNI).approve(address(swapContract), amountIn);

        uint256 amountOut = swapContract.swapTokenForETH(TOKEN_UNI, amountIn);

        uint256 tokenABalanceAfter = user.balance;
        uint256 tokenBBalanceAfter = IERC20(TOKEN_UNI).balanceOf(user);

        assertEq(tokenBBalanceAfter, balB - amountIn, "Token B balance incorrect after swap");
        assertEq(tokenABalanceAfter, balA + amountOut, "Token A balance incorrect after swap");

        vm.stopPrank();
    }

    function testSwapEthToToken() public {
        vm.startPrank(user);

        uint256 amountIn = 5e15;

        uint256 balB = IERC20(TOKEN_UNI).balanceOf(user);
        uint256 balA = user.balance;

        uint256 amountOut = swapContract.swapETHForToken{value: amountIn}(TOKEN_UNI);

        uint256 tokenABalanceAfter = user.balance;
        uint256 tokenBBalanceAfter = IERC20(TOKEN_UNI).balanceOf(user);

        assertEq(tokenABalanceAfter, balA - amountIn, "Token A balance incorrect after swap");
        assertEq(tokenBBalanceAfter, balB + amountOut, "Token B balance incorrect after swap");

        vm.stopPrank();
    }

    function testGetPriceETHtoToken() public {
        vm.startPrank(user);
        uint256 amountIn = 1e16;
        uint256 amountOut = swapContract.getPriceETHtoToken(TOKEN_UNI, amountIn);

        console.log("Estimated UNI for 0.01 ETH:", amountOut);
        assertGt(amountOut, 0, "Price query failed");

        vm.stopPrank();
    }

    function testGetPriceTokenToETH() public {
        vm.startPrank(user);
        uint256 amountIn = 1e16;
        uint256 amountOut = swapContract.getPriceETHtoToken(TOKEN_UNI, amountIn);

        console.log("Estimated ETH for 0.01 UNI:", amountOut);
        assertGt(amountOut, 0, "Price query failed");

        vm.stopPrank();
    }

    function testGetPriceTokenToToken() public {
        vm.startPrank(user);
        uint256 amountIn = 1e16;
        uint256 amountOut = swapContract.getPriceTokenToToken(TOKEN_UNI, TOKEN_JSN, amountIn);

        console.log("Estimated JSN for 0.01 UNI:", amountOut);
        assertGt(amountOut, 0, "Price query failed");

        vm.stopPrank();
    }

    function testSetSlippageBP() public {
        vm.startPrank(user);

        uint256 slippage = swapContract.slippageBasisPoints();

        assertEq(slippage, 1000);

        uint16 newSlippage = 300; // 3%
        swapContract.setSlippageBP(newSlippage);

        slippage = swapContract.slippageBasisPoints();
        assertEq(slippage, newSlippage, "Slippage BP not set correctly");

        vm.stopPrank();
    }

    function testGetPairAddress() public view {
        address pairAddress = swapContract.getPairAddress(TOKEN_WETH, TOKEN_UNI);
        console.log("Pair address WETH-UNI:", pairAddress);
        assertNotEq(pairAddress, address(0), "Pair does not exist");
    }

    function testGetPairRatioAmount() public view {
        uint256 amountA = 1e16;
        uint256 amountB = swapContract.getPairRatioAmount(TOKEN_WETH, TOKEN_UNI, amountA, TOKEN_WETH);
        assertGt(amountB, 0, "Get pair ratio amount failed");
    }

    function testIsFirstLiquidity() public {
        bool isFirst = swapContract.isFirstLiquidity(TOKEN_WETH, TOKEN_UNI);
        console.log("Is first liquidity WETH-UNI:", isFirst);
        assertFalse(isFirst, "Liquidity already exists, should be false");

        swapContract.createPool(TOKEN_WETH, address(1011));

        isFirst = swapContract.isFirstLiquidity(TOKEN_WETH, address(1011));
        assertTrue(isFirst, "Liquidity should not exist for new pair");
    }

    function testCreatePool() public {
        vm.startPrank(user);

        address newToken = address(2022);
        address pairAddress = swapContract.getPairAddress(TOKEN_WETH, newToken);
        assertEq(pairAddress, address(0), "Pair should not exist yet");

        swapContract.createPool(TOKEN_WETH, newToken);

        pairAddress = swapContract.getPairAddress(TOKEN_WETH, newToken);
        assertNotEq(pairAddress, address(0), "Pair creation failed");

        vm.stopPrank();
    }

    function testAddLiquidity() public {
        vm.startPrank(user);

        uint256 amountA = 1e14;
        uint256 amountB = swapContract.getPairRatioAmount(TOKEN_JSN, TOKEN_UNI, amountA, TOKEN_JSN);

        IERC20(TOKEN_JSN).approve(address(swapContract), amountA);
        IERC20(TOKEN_UNI).approve(address(swapContract), amountB);

        uint256 liquidity = swapContract.addLiquidity(TOKEN_JSN, TOKEN_UNI, amountA, amountB);

        console.log("Liquidity tokens received:", liquidity);
        assertGt(liquidity, 0, "Add liquidity failed");

        amountB = 3e15;
        amountA = swapContract.getPairRatioAmount(TOKEN_JSN, TOKEN_UNI, amountB, TOKEN_UNI);

        IERC20(TOKEN_JSN).approve(address(swapContract), amountA);
        IERC20(TOKEN_UNI).approve(address(swapContract), amountB);

        liquidity = swapContract.addLiquidity(TOKEN_JSN, TOKEN_UNI, amountA, amountB);

        console.log("Liquidity tokens received:", liquidity);
        assertGt(liquidity, 0, "Add liquidity failed");

        vm.stopPrank();
    }

    function testNewAddLiquidity() public {
        vm.startPrank(user);

        JasonToken newToken = new JasonToken(user, user);

        uint256 amountA = 1e14;
        uint256 amountB = 2e14;

        vm.expectRevert();
        swapContract.getPairRatioAmount(address(newToken), TOKEN_UNI, amountA, address(newToken));

        swapContract.createPool(address(newToken), TOKEN_UNI);
        assertEq(swapContract.isFirstLiquidity(address(newToken), TOKEN_UNI), true);

        newToken.approve(address(swapContract), amountA);
        IERC20(TOKEN_UNI).approve(address(swapContract), amountB);

        uint256 liquidity = swapContract.addLiquidity(address(newToken), TOKEN_UNI, amountA, amountB);
        console.log("Liquidity tokens received (1st):", liquidity);
        assertGt(liquidity, 0, "Add liquidity failed");

        assertEq(swapContract.isFirstLiquidity(address(newToken), TOKEN_UNI), false);

        amountA = 2e14;
        amountB = swapContract.getPairRatioAmount(address(newToken), TOKEN_UNI, amountA, address(newToken));

        newToken.approve(address(swapContract), amountA);
        IERC20(TOKEN_UNI).approve(address(swapContract), amountB);

        liquidity = swapContract.addLiquidity(address(newToken), TOKEN_UNI, amountA, amountB);
        console.log("Liquidity tokens received (2nd):", liquidity);
        assertGt(liquidity, 0, "Add liquidity failed");

        vm.stopPrank();
    }

    function testAddLiquidityETH() public {
        vm.startPrank(user);

        uint256 amountA = 1e14;
        uint256 amountB = swapContract.getPairRatioAmount(TOKEN_JSN, TOKEN_WETH, amountA, TOKEN_JSN);

        IERC20(TOKEN_JSN).approve(address(swapContract), amountA);

        uint256 liquidity = swapContract.addLiquidityETH{value: amountB}(TOKEN_JSN, amountA);

        console.log("Liquidity tokens received:", liquidity);
        assertGt(liquidity, 0, "Add liquidity failed");

        amountB = 3e14;
        amountA = swapContract.getPairRatioAmount(TOKEN_JSN, TOKEN_WETH, amountB, TOKEN_WETH);

        IERC20(TOKEN_JSN).approve(address(swapContract), amountA);

        liquidity = swapContract.addLiquidityETH{value: amountB}(TOKEN_JSN, amountA);

        console.log("Liquidity tokens received:", liquidity);
        assertGt(liquidity, 0, "Add liquidity failed");

        vm.stopPrank();
    }

    function testNewAddLiquidityETH() public {
        vm.startPrank(user);

        JasonToken newToken = new JasonToken(user, user);

        uint256 amountA = 1e14;
        uint256 amountB = 2e14;

        vm.expectRevert();
        swapContract.getPairRatioAmount(address(newToken), TOKEN_WETH, amountA, address(newToken));

        swapContract.createPool(address(newToken), TOKEN_WETH);
        assertEq(swapContract.isFirstLiquidity(address(newToken), TOKEN_WETH), true);

        newToken.approve(address(swapContract), amountA);

        uint256 liquidity = swapContract.addLiquidityETH{value: amountB}(address(newToken), amountA);
        console.log("Liquidity tokens received (1st):", liquidity);
        assertGt(liquidity, 0, "Add liquidity failed");

        assertEq(swapContract.isFirstLiquidity(address(newToken), TOKEN_WETH), false);

        amountA = 2e14;
        amountB = swapContract.getPairRatioAmount(address(newToken), TOKEN_WETH, amountA, address(newToken));

        newToken.approve(address(swapContract), amountA);

        liquidity = swapContract.addLiquidityETH{value: amountB}(address(newToken), amountA);
        console.log("Liquidity tokens received (2nd):", liquidity);
        assertGt(liquidity, 0, "Add liquidity failed");

        vm.stopPrank();
    }

    function testGetLiquidityBalance() public {
        vm.startPrank(user);

        uint256 liquidity = swapContract.getLiquidityBalance(TOKEN_JSN, TOKEN_UNI, user);
        assertGt(liquidity, 0, "Get liquidity balance failed");

        uint256 liquidityETH = swapContract.getLiquidityBalanceETH(TOKEN_JSN, user);
        assertGt(liquidityETH, 0, "Get liquidity balance ETH failed");

        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        vm.startPrank(user);

        uint256 liquidityBefore = swapContract.getLiquidityBalance(TOKEN_JSN, TOKEN_UNI, user);
        address pair = swapContract.getPairAddress(TOKEN_JSN, TOKEN_UNI);

        IUniswapV2Pair(pair).approve(address(swapContract), liquidityBefore / 2);

        swapContract.removeLiquidity(TOKEN_JSN, TOKEN_UNI, liquidityBefore / 2);

        uint256 liquidityAfter = swapContract.getLiquidityBalance(TOKEN_JSN, TOKEN_UNI, user);
        assertEq(liquidityAfter, liquidityBefore / 2, "Liquidity balance incorrect after removal");

        vm.stopPrank();
    }

    function testRemoveLiquidityEth() public {
        vm.startPrank(user);

        uint256 liquidityBefore = swapContract.getLiquidityBalance(TOKEN_JSN, TOKEN_WETH, user);
        address pair = swapContract.getPairAddress(TOKEN_JSN, TOKEN_WETH);

        IUniswapV2Pair(pair).approve(address(swapContract), liquidityBefore / 2);

        swapContract.removeLiquidityETH(TOKEN_JSN, liquidityBefore / 2);

        uint256 liquidityAfter = swapContract.getLiquidityBalance(TOKEN_JSN, TOKEN_WETH, user);
        assertEq(liquidityAfter, liquidityBefore / 2, "Liquidity balance incorrect after removal");

        vm.stopPrank();
    }

    function testZapIn() public {
        vm.startPrank(user);

        uint256 amountIn = 5000e18;

        uint256 balJSN = IERC20(TOKEN_JSN).balanceOf(user);

        IERC20(TOKEN_JSN).approve(address(swapContract), amountIn);
        IERC20(TOKEN_UNI).approve(address(swapContract), amountIn);

        uint256 liquidity = swapContract.zapIn(TOKEN_JSN, TOKEN_JSN, TOKEN_UNI, amountIn);

        uint256 balJSNAfter = IERC20(TOKEN_JSN).balanceOf(user);

        assertLt(balJSNAfter, balJSN, "JSN balance should decrease after zap in");
        assertGt(liquidity, 0, "Zap in liquidity should be greater than zero");

        uint256 zapJSNBal = IERC20(TOKEN_JSN).balanceOf(address(swapContract));
        uint256 zapUNIBal = IERC20(TOKEN_UNI).balanceOf(address(swapContract));
        assertLe(zapJSNBal, 3e14, "Zap contract should not retain significant JSN tokens");
        assertLe(zapUNIBal, 3e14, "Zap contract should not retain significant UNI tokens");

        vm.stopPrank();
    }

    function testZapInFromEth() public {
        vm.startPrank(user);

        uint256 amountIn = 5e14;

        uint256 balEth = user.balance;

        IERC20(TOKEN_UNI).approve(address(swapContract), amountIn);

        uint256 liquidity = swapContract.zapInFromEth{value: amountIn}(TOKEN_UNI);

        uint256 balEthAfter = user.balance;

        assertLt(balEthAfter, balEth, "ETH balance should decrease after zap in");
        assertGt(liquidity, 0, "Zap in liquidity should be greater than zero");

        uint256 zapEthBal = address(swapContract).balance;
        uint256 zapUNIBal = IERC20(TOKEN_UNI).balanceOf(address(swapContract));
        assertLe(zapEthBal, 3e14, "Zap contract should not retain significant ETH");
        assertLe(zapUNIBal, 3e14, "Zap contract should not retain significant UNI tokens");

        vm.stopPrank();
    }

    function testZapInToEth() public {
        vm.startPrank(user);
        deal(TOKEN_UNI, user, 1e18);

        uint256 amountIn = 5e14;
        uint256 balUni = IERC20(TOKEN_UNI).balanceOf(user);

        IERC20(TOKEN_UNI).approve(address(swapContract), amountIn);

        uint256 liquidity = swapContract.zapInToEth(TOKEN_UNI, amountIn);

        uint256 balUniAfter = IERC20(TOKEN_UNI).balanceOf(user);

        assertEq(balUniAfter, balUni - amountIn, "UNI balance should decrease after zap in");
        assertGt(liquidity, 0, "Zap in liquidity should be greater than zero");

        uint256 zapEthBal = address(swapContract).balance;
        uint256 zapUNIBal = IERC20(TOKEN_UNI).balanceOf(address(swapContract));
        assertLe(zapEthBal, 3e14, "Zap contract should not retain significant ETH");
        assertLe(zapUNIBal, 3e14, "Zap contract should not retain significant UNI tokens");

        vm.stopPrank();
    }

    function testZapOutEth() public {
        vm.startPrank(user);

        uint256 liquidityBefore = swapContract.getLiquidityBalance(TOKEN_JSN, TOKEN_WETH, user);
        address pair = swapContract.getPairAddress(TOKEN_JSN, TOKEN_WETH);

        IUniswapV2Pair(pair).approve(address(swapContract), liquidityBefore / 2);

        swapContract.zapOutEth(TOKEN_JSN, liquidityBefore / 2);

        uint256 liquidityAfter = swapContract.getLiquidityBalance(TOKEN_JSN, TOKEN_WETH, user);
        assertEq(liquidityAfter, liquidityBefore / 2, "Liquidity balance incorrect after removal");

        vm.stopPrank();
    }
}
