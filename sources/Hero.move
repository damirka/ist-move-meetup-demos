module hero::coin {
    use sui::transfer;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::tx_context::{Self, TxContext};

    struct GOLD has drop {}

    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            coin::create_currency(GOLD {}, ctx),
            tx_context::sender(ctx)
        )
    }

    public fun mint(
        treasury: &mut TreasuryCap<GOLD>,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<GOLD> {
        coin::mint(treasury, amount, ctx)
    }

    entry fun mint_and_send(
        treasury: &mut TreasuryCap<GOLD>,
        amount: u64,
        receiver: address,
        ctx: &mut TxContext
    ) {
        transfer::transfer(
            mint(treasury, amount, ctx),
            receiver
        )
    }
}

module hero::hero {
    use sui::transfer;
    use sui::object::{Self, Info};
    use sui::tx_context::{Self, TxContext};

    /// Our hero to use in different games.
    struct Hero has key {
        info: Info,
        name: vector<u8>
    }

    entry fun create(name: vector<u8>, ctx: &mut TxContext) {
        let hero = Hero {
            info: object::new(ctx),
            name
        };

        transfer::transfer(hero, tx_context::sender(ctx))
    }
}

module 0x0::sword_shop {
    use sui::transfer::{Self, transfer_to_object as tr_obj};
    use sui::coin::{Self, Coin};
    use sui::object::{Self, Info};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{TxContext};

    // our Gold coin
    use hero::coin::GOLD;

    const CLASS_COMMON: u8 = 10;
    const CLASS_RARE: u8 = 50;
    const CLASS_EPIC: u8 = 100;

    struct Listing has key {
        info: Info,
        sword: Sword,
        price: u64
    }

    struct Sword has key, store {
        info: Info,
        power: u64,
        item_class: u8,
    }

    struct SwordShop has key {
        info: Info,
        balance: Balance<GOLD>
    }

    fun init(ctx: &mut TxContext) {
        let shop = SwordShop {
            info: object::new(ctx),
            balance: balance::zero()
        };

        tr_obj(list_sword(100000, CLASS_EPIC, 1000000000, ctx), &mut shop);
        tr_obj(list_sword(100, CLASS_EPIC, 100000, ctx), &mut shop);
        tr_obj(list_sword(10, CLASS_COMMON, 1000, ctx), &mut shop);
        tr_obj(list_sword(10, CLASS_COMMON, 1000, ctx), &mut shop);
        tr_obj(list_sword(50, CLASS_RARE, 10000, ctx), &mut shop);
        tr_obj(list_sword(50, CLASS_RARE, 10000, ctx), &mut shop);
        tr_obj(list_sword(50, CLASS_RARE, 10000, ctx), &mut shop);


        transfer::share_object(shop);
    }

    public entry fun buy_sword<T: key + store>(
        character: &mut T,
        shop: &mut SwordShop,
        listing: Listing,
        coin: Coin<GOLD>
    ) {
        assert!(coin::value(&coin) == listing.price, 0);

        // keep the money bruh
        let balance = coin::into_balance(coin);
        balance::join(&mut shop.balance, balance);

        let Listing { info, sword, price: _ } = listing;

        object::delete(info);

        tr_obj(sword, character)
    }

    fun list_sword(
        power: u64,
        item_class: u8,
        price: u64,
        ctx: &mut TxContext
    ): Listing {
        Listing {
            info: object::new(ctx),
            sword: Sword {
                info: object::new(ctx),
                power,
                item_class
            },
            price
        }
    }
}
