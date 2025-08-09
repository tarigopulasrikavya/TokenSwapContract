module Tok::TokenSwap {
    use aptos_framework::signer;
    use aptos_framework::coin::{Self, Coin};
    use std::error;

    /// Error codes
    const E_INSUFFICIENT_BALANCE: u64 = 1;
    const E_POOL_NOT_EXISTS: u64 = 2;

    /// Struct representing a token swap pool that actually holds the coins
    struct SwapPool<phantom TokenA, phantom TokenB> has store, key {
        token_a_reserve: Coin<TokenA>,  // Actual Token A coins in the pool
        token_b_reserve: Coin<TokenB>,  // Actual Token B coins in the pool
    }

    /// Function to create a new swap pool with initial liquidity (1:1 ratio)
    public fun create_pool<TokenA, TokenB>(
        owner: &signer, 
        token_a_amount: u64, 
        token_b_amount: u64
    ) {
        // Withdraw tokens from owner to create pool reserves
        let token_a_coins = coin::withdraw<TokenA>(owner, token_a_amount);
        let token_b_coins = coin::withdraw<TokenB>(owner, token_b_amount);
        
        // Create new swap pool with actual coins
        let pool = SwapPool<TokenA, TokenB> {
            token_a_reserve: token_a_coins,
            token_b_reserve: token_b_coins,
        };

        move_to(owner, pool);
    }

    /// Function to swap Token A for Token B (1:1 ratio)
    public fun swap_a_to_b<TokenA, TokenB>(
        user: &signer,
        pool_owner: address,
        amount: u64
    ) acquires SwapPool {
        // Check if pool exists
        assert!(exists<SwapPool<TokenA, TokenB>>(pool_owner), error::not_found(E_POOL_NOT_EXISTS));
        
        let pool = borrow_global_mut<SwapPool<TokenA, TokenB>>(pool_owner);
        
        // Check if pool has enough Token B
        assert!(coin::value(&pool.token_b_reserve) >= amount, error::invalid_argument(E_INSUFFICIENT_BALANCE));

        // Withdraw Token A from user
        let user_token_a = coin::withdraw<TokenA>(user, amount);
        
        // Extract Token B from pool
        let token_b_for_user = coin::extract(&mut pool.token_b_reserve, amount);
        
        // Add user's Token A to pool and give Token B to user
        coin::merge(&mut pool.token_a_reserve, user_token_a);
        coin::deposit<TokenB>(signer::address_of(user), token_b_for_user);
    }
}