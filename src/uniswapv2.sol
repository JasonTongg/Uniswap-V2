// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function balanceOf(address owner) external view returns (uint256);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function balanceOf(address owner) external view returns (uint256);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function totalSupply() external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 value) external returns (bool);
}

interface IUniswapV2Router {
    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

contract TokenSwapContract {
    address public immutable ROUTER;
    IUniswapV2Router public router = IUniswapV2Router(ROUTER);

    uint256 public slippageBasisPoints = 1000;

    address public immutable FACTORY;
    IUniswapV2Factory public factory = IUniswapV2Factory(FACTORY);

    event Swapped(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event PoolCreated(address tokenA, address tokenB, address pair);
    event LiquidityAdded(address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 liquidity);
    event Received(address sender, uint256 amount);

    constructor(address factoryAddress, address routerAddress) {
        factory = IUniswapV2Factory(factoryAddress);
        router = IUniswapV2Router(routerAddress);
    }

    function _getMinAmountOut(address[] memory path, uint256 amountIn) internal view returns (uint256) {
        uint256[] memory amountsOut = router.getAmountsOut(amountIn, path);
        uint256 estimated = amountsOut[amountsOut.length - 1];
        return (estimated * (10000 - slippageBasisPoints)) / 10000;
    }

    function swapToken(address tokenIn, address tokenOut, uint256 amountIn) public returns (uint256) {
        require(getPairAddress(tokenIn, tokenOut) != address(0), "Pool does not exist");
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(router), amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256 amountOutMin = _getMinAmountOut(path, amountIn);

        uint256[] memory amounts =
            router.swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender, block.timestamp + 300);

        emit Swapped(msg.sender, tokenIn, tokenOut, amountIn, amounts[1]);

        return amounts[1];
    }

    function swapETHForToken(address tokenOut) external payable returns (uint256) {
        require(getPairAddress(router.WETH(), tokenOut) != address(0), "Pool does not exist");
        require(msg.value > 0, "No ETH");

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenOut;

        uint256 amountOutMin = _getMinAmountOut(path, msg.value);

        uint256[] memory amounts =
            router.swapExactETHForTokens{value: msg.value}(amountOutMin, path, msg.sender, block.timestamp + 300);

        emit Swapped(msg.sender, address(0), tokenOut, msg.value, amountOutMin);
        return amounts[1];
    }

    function swapTokenForETH(address tokenIn, uint256 amountIn) external returns (uint256) {
        require(getPairAddress(tokenIn, router.WETH()) != address(0), "Pool does not exist");
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(router), amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = router.WETH();

        uint256 amountOutMin = _getMinAmountOut(path, amountIn);

        uint256[] memory amounts =
            router.swapExactTokensForETH(amountIn, amountOutMin, path, msg.sender, block.timestamp + 300);

        emit Swapped(msg.sender, tokenIn, address(0), amountIn, amounts[1]);

        return amounts[1];
    }

    function getPriceETHtoToken(address tokenOut, uint256 amountETHIn) external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenOut;
        return router.getAmountsOut(amountETHIn, path)[1];
    }

    function getPriceTokenToETH(address tokenIn, uint256 amountTokenIn) external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = router.WETH();
        return router.getAmountsOut(amountTokenIn, path)[1];
    }

    function getPriceTokenToToken(address tokenIn, address tokenOut, uint256 amountTokenIn)
        external
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        return router.getAmountsOut(amountTokenIn, path)[1];
    }

    function setSlippageBP(uint256 newSlippageBasisPoints) external {
        require(newSlippageBasisPoints <= 1000, "Max 10%");
        slippageBasisPoints = newSlippageBasisPoints;
    }

    function createPool(address tokenA, address tokenB) external returns (address pair) {
        pair = getPairAddress(tokenA, tokenB);
        if (pair == address(0)) {
            pair = factory.createPair(tokenA, tokenB);
        }
        emit PoolCreated(tokenA, tokenB, pair);
    }

    function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB)
        public
        returns (uint256 liquidity)
    {
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        IERC20(tokenA).approve(address(router), amountA);
        IERC20(tokenB).approve(address(router), amountB);

        uint256 amountAMin = amountA * (10000 - slippageBasisPoints) / 10000;
        uint256 amountBMin = amountB * (10000 - slippageBasisPoints) / 10000;

        (,, liquidity) = router.addLiquidity(
            tokenA, tokenB, amountA, amountB, amountAMin, amountBMin, msg.sender, block.timestamp + 300
        );

        emit LiquidityAdded(tokenA, tokenB, amountA, amountB, liquidity);
    }

    function addLiquidityETH(address token, uint256 amountToken) external payable returns (uint256 liquidity) {
        IERC20(token).transferFrom(msg.sender, address(this), amountToken);

        IERC20(token).approve(address(router), amountToken);

        uint256 amountAMin = amountToken * (10000 - slippageBasisPoints) / 10000;
        uint256 amountEthMin = uint256(msg.value) * (10000 - slippageBasisPoints) / 10000;

        (,, liquidity) = router.addLiquidityETH{value: msg.value}(
            token, amountToken, amountAMin, amountEthMin, msg.sender, block.timestamp + 300
        );

        emit LiquidityAdded(token, address(0), amountToken, msg.value, liquidity);
    }

    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity)
        external
        returns (uint256 amountA, uint256 amountB)
    {
        address pair = getPairAddress(tokenA, tokenB);
        require(pair != address(0), "Pool does not exist");
        require(liquidity > 0, "No LP to remove");

        IUniswapV2Pair(pair).transferFrom(msg.sender, address(this), liquidity);
        IUniswapV2Pair(pair).approve(address(router), liquidity);

        (amountA, amountB) = router.removeLiquidity(tokenA, tokenB, liquidity, 0, 0, msg.sender, block.timestamp + 300);
    }

    function removeLiquidityETH(address token, uint256 liquidity)
        external
        returns (uint256 amountToken, uint256 amountETH)
    {
        address pair = getPairAddress(token, router.WETH());
        require(pair != address(0), "Pool does not exist");
        require(liquidity > 0, "No LP to remove");

        IUniswapV2Pair(pair).transferFrom(msg.sender, address(this), liquidity);
        IUniswapV2Pair(pair).approve(address(router), liquidity);

        (amountToken, amountETH) = router.removeLiquidityETH(token, liquidity, 0, 0, msg.sender, block.timestamp + 300);
    }

    function getLiquidityBalance(address tokenA, address tokenB, address user)
        external
        view
        returns (uint256 liquidity)
    {
        address pair = getPairAddress(tokenA, tokenB);
        if (pair == address(0)) {
            return 0;
        }
        liquidity = IUniswapV2Pair(pair).balanceOf(user);
    }

    function getLiquidityBalanceETH(address token, address user) external view returns (uint256 liquidity) {
        address pair = getPairAddress(token, router.WETH());
        if (pair == address(0)) {
            return 0;
        }
        liquidity = IUniswapV2Pair(pair).balanceOf(user);
    }

    function getPairAddress(address tokenA, address tokenB) public view returns (address pair) {
        pair = factory.getPair(tokenA, tokenB);
    }

    function getPairRatioAmount(address tokenA, address tokenB, uint256 tokenAmount, address tokenIn)
        external
        view
        returns (uint256 tokenPairAmount)
    {
        address pair = getPairAddress(tokenA, tokenB);
        require(pair != address(0), "Pool does not exist");

        address token0 = IUniswapV2Pair(pair).token0();
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();

        uint256 reserveA;
        uint256 reserveB;

        if (token0 == tokenA) {
            reserveA = reserve0;
            reserveB = reserve1;
        } else {
            reserveA = reserve1;
            reserveB = reserve0;
        }

        uint256 amountB;

        if (tokenIn == tokenA) {
            amountB = (tokenAmount * reserveB) / reserveA;
        } else {
            amountB = (tokenAmount * reserveA) / reserveB;
        }

        return amountB;
    }

    function isFirstLiquidity(address tokenA, address tokenB) external view returns (bool) {
        address pair = getPairAddress(tokenA, tokenB);

        require(pair != address(0), "Pool does not exist");

        (uint112 reserveA, uint112 reserveB,) = IUniswapV2Pair(pair).getReserves();

        if (reserveA == 0 && reserveB == 0) {
            return true;
        }

        return false;
    }

    function zapIn(address tokenIn, address tokenA, address tokenB, uint256 amountIn)
        external
        returns (uint256 liquidity)
    {
        require(amountIn > 0, "Invalid amount");
        require(tokenIn == tokenA || tokenIn == tokenB, "tokenIn must be tokenA or tokenB");
        require(tokenA != tokenB, "tokenA and tokenB must be different");

        address pair = getPairAddress(tokenA, tokenB);
        require(pair != address(0), "Pool does not exist");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        uint256 swapAmount = amountIn / 2;

        address tokenOut = (tokenIn == tokenA) ? tokenB : tokenA;

        IERC20(tokenIn).approve(address(router), swapAmount);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amounts =
            router.swapExactTokensForTokens(swapAmount, 0, path, address(this), block.timestamp + 300);

        uint256 swappedOut = amounts[1];

        uint256 amountA;
        uint256 amountB;

        if (tokenIn == tokenA) {
            amountA = amountIn - swapAmount;
            amountB = swappedOut;
        } else {
            amountA = swappedOut;
            amountB = amountIn - swapAmount;
        }

        IERC20(tokenA).approve(address(router), amountA);
        IERC20(tokenB).approve(address(router), amountB);

        uint256 amountAMin = amountA * (10000 - slippageBasisPoints) / 10000;
        uint256 amountBMin = amountB * (10000 - slippageBasisPoints) / 10000;

        (,, liquidity) = router.addLiquidity(
            tokenA, tokenB, amountA, amountB, amountAMin, amountBMin, msg.sender, block.timestamp + 300
        );

        emit LiquidityAdded(tokenA, tokenB, amountA, amountB, liquidity);
    }

    function zapInFromEth(address token) external payable returns (uint256 liquidity) {
        require(msg.value > 0, "Invalid amount");

        address pair = getPairAddress(token, router.WETH());
        require(pair != address(0), "Pool does not exist");

        uint256 swapAmount = msg.value / 2;

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = token;

        uint256[] memory amounts =
            router.swapExactETHForTokens{value: swapAmount}(0, path, address(this), block.timestamp + 300);

        uint256 swappedOut = amounts[1];

        uint256 amountA = swappedOut;
        uint256 amountB = msg.value - swapAmount;

        IERC20(token).approve(address(router), amountA);

        uint256 amountAMin = amountA * (10000 - slippageBasisPoints) / 10000;
        uint256 amountEthMin = uint256(amountB) * (10000 - slippageBasisPoints) / 10000;

        (,, liquidity) = router.addLiquidityETH{value: amountB}(
            token, amountA, amountAMin, amountEthMin, msg.sender, block.timestamp + 300
        );

        emit LiquidityAdded(token, router.WETH(), amountA, amountB, liquidity);
    }

    function zapInToEth(address token, uint256 amountIn) external returns (uint256 liquidity) {
        require(amountIn > 0, "Invalid amount");

        address pair = getPairAddress(token, router.WETH());
        require(pair != address(0), "Pool does not exist");

        IERC20(token).transferFrom(msg.sender, address(this), amountIn);

        uint256 swapAmount = amountIn / 2;

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();

        IERC20(token).approve(address(router), swapAmount);

        uint256[] memory amounts =
            router.swapExactTokensForETH(swapAmount, 0, path, address(this), block.timestamp + 300);

        uint256 swappedOut = amounts[1];

        uint256 amountA = amountIn - swapAmount;
        uint256 amountB = swappedOut;

        IERC20(token).approve(address(router), amountA);

        uint256 amountAMin = amountA * (10000 - slippageBasisPoints) / 10000;
        uint256 amountEthMin = uint256(amountB) * (10000 - slippageBasisPoints) / 10000;

        (,, liquidity) = router.addLiquidityETH{value: amountB}(
            token, amountA, amountAMin, amountEthMin, msg.sender, block.timestamp + 300
        );

        emit LiquidityAdded(token, router.WETH(), amountA, amountB, liquidity);
    }

    function zapOutEth(address token, uint256 liquidity) external returns (uint256 amountEth) {
        address pair = getPairAddress(token, router.WETH());
        require(pair != address(0), "Pool does not exist");
        require(liquidity > 0, "No LP to remove");

        uint256 amountETH;
        uint256 amountToken;

        IUniswapV2Pair(pair).transferFrom(msg.sender, address(this), liquidity);
        IUniswapV2Pair(pair).approve(address(router), liquidity);

        (amountToken, amountETH) =
            router.removeLiquidityETH(token, liquidity, 0, 0, address(this), block.timestamp + 300);

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();

        uint256 swapAmount = amountToken;

        IERC20(token).approve(address(router), swapAmount);

        uint256[] memory amounts = router.swapExactTokensForETH(swapAmount, 0, path, msg.sender, block.timestamp + 300);

        return amounts[1] + amountETH;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
