module Tok::TokenSwap {
    use aptos_framework::signer;
    use aptos_framework::coin::{Self, Coin};
    use std::error;

    const E_INSUFFICIENT_BALANCE: u64 = 1;
    const E_POOL_NOT_EXISTS: u64 = 2;

    struct SwapPool<phantom TokenA, phantom TokenB> has store, key {
        token_a_reserve: Coin<TokenA>,  
        token_b_reserve: Coin<TokenB>,  
    }

    
    public fun create_pool<TokenA, TokenB>(
        owner: &signer, 
        token_a_amount: u64, 
        token_b_amount: u64
    ) {
       
        let token_a_coins = coin::withdraw<TokenA>(owner, token_a_amount);
        let token_b_coins = coin::withdraw<TokenB>(owner, token_b_amount);
        
        
        let pool = SwapPool<TokenA, TokenB> {
            token_a_reserve: token_a_coins,
            token_b_reserve: token_b_coins,
        };

        move_to(owner, pool);
    }

 
    public fun swap_a_to_b<TokenA, TokenB>(
        user: &signer,
        pool_owner: address,
        amount: u64
    ) acquires SwapPool {
       
        assert!(exists<SwapPool<TokenA, TokenB>>(pool_owner), error::not_found(E_POOL_NOT_EXISTS));
        
        let pool = borrow_global_mut<SwapPool<TokenA, TokenB>>(pool_owner);
        
        assert!(coin::value(&pool.token_b_reserve) >= amount, error::invalid_argument(E_INSUFFICIENT_BALANCE));

      
        let user_token_a = coin::withdraw<TokenA>(user, amount);
    
        let token_b_for_user = coin::extract(&mut pool.token_b_reserve, amount);
        
       
        coin::merge(&mut pool.token_a_reserve, user_token_a);
        coin::deposit<TokenB>(signer::address_of(user), token_b_for_user);
    }

}
