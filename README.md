# Uniswap Integration

This repository demonstrates integration and usage of the Uniswap V2 protocol. including liquidity provisioning, token swaps, and general on-chain interactions using Uniswap V2.  

## About the Project

Uniswap V2 is a decentralized exchange protocol based on an automated market maker model. It provides core smart contracts (factory, pair contracts) and periphery contracts (router, libraries) to allow for token swaps, liquidity add/remove, and pair creation. :contentReference[oaicite:1]{index=1}

This repo includes smart contracts, tests, and scripts to work with Uniswap V2. ideal for developers who want a hands-on example of deploying, testing, and interacting with Uniswap V2 on Ethereum or compatible networks.


- **Live Product:** [Zypher](https://zypher-dex.vercel.app/)
- **Frontend using Nextjs:** [Zypher Frontend](https://github.com/JasonTongg/Zypher)

## What's Inside

- `src/` — example solidity contracts interacting with Uniswap V2  
- `script/` — deployment or utility scripts
- `test/` — test cases / unit tests for contract functionality  
- `lib/`, `.gitmodules`, etc — supporting libraries or submodules  
- Configuration files: `foundry.toml`, etc — for build, test, and deployment setup  

## Supported Actions / Features

- Deploy Uniswap V2 core + periphery contracts on local / testnet environment  
- Create new token pairs and provide liquidity  
- Execute token swaps (ERC-20 ↔ ERC-20, or via WETH wrapper for ETH)  
- Remove liquidity from pools  
- Example usage of router contract for swap & liquidity functions  
- On-chain unit tests to verify correct behaviour  

## Getting Started

### Prerequisites

- An Ethereum-compatible environment (testnet)  
- Solidity toolchain (Foundry)  
- Node / npm

## References & Protocol Info

- Uniswap V2 Contracts overview: factory, pairs, router, periphery. 
- The protocol’s design makes token-pair creation & liquidity pools generic and composable.

## Usage Guide
**Swap Tokens**
- Approve token A to router
- Use router’s swapExactTokensForTokens
- Receive token B (optionally via WETH if swapping from/to ETH)

**Add Liquidity**
- Deploy or reference existing Token A / Token B contracts
- Approve tokens to router (both sides)
- Call router’s addLiquidity (or addLiquidityETH if ETH)
- LP tokens are minted representing share in pool

**Remove Liquidity**
- Approve LP token to router
- Call removeLiquidity (or removeLiquidityETH)
- Receive underlying tokens (or ETH + token)

## **Zap In (Single Token → LP Position)**
Zap In allows users to provide liquidity **using only one token**, rather than both sides of the pair.

Typical flow:

1. User selects a single token (e.g., Token A)  
2. Contract estimates optimal split between Token A and Token B  
3. Half of Token A is swapped into Token B  
4. Router receives the balanced Token A + Token B amounts  
5. `addLiquidity` is executed internally  
6. User receives LP tokens — **all in one transaction**

This is helpful for users who don’t want to perform manual swaps before adding liquidity.

## **Zap Out (LP Token → Single Token)**
Zap Out lets users withdraw liquidity and receive **one token only**, instead of both.

Typical flow:

1. User approves LP token to the Zap contract  
2. Contract calls `removeLiquidity` to receive Token A + Token B  
3. One of the tokens is swapped entirely into the target token  
4. User receives final output in **one single token** (e.g., only Token A)

This simplifies LP withdrawal and avoids users manually swapping remaining tokens.

### Benefits of Zap In / Zap Out
- Single-transaction liquidity management  
- No need to manually calculate token ratios  
- Smoother UX for new users  
- Automatic optimal routing for swaps  
- Reduces gas and transaction complexity  

## Author  

**Jason Tong**  

- **Product:** [Zypher](https://zypher-dex.vercel.app/).
- **GitHub:** [JasonTongg](https://github.com/JasonTongg).
- **Linkedin:** [Jason Tong](https://www.linkedin.com/in/jason-tong-42600319a/).
