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

    entry fun mint(
        treasury: &mut TreasuryCap<GOLD>,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<GOLD> {
        coin::mint(treasury, amount, ctx)
    }
}

module hero::hero {
    use sui::transfer;
    use sui::id::VersionedID;
    use sui::tx_context::{Self, TxContext};

    /// Our hero to use in different games.
    struct Hero has key {
        id: VersionedID,
        name: vector<u8>
    }

    entry fun create(name: vector<u8>, ctx: &mut TxContext) {
        let hero = Hero {
            id: tx_context::new_id(ctx),
            name
        };

        transfer::transfer(hero, tx_context::sender(ctx))
    }
}

module 0x0::sword_shop {
    use sui::transfer::{Self, transfer_to_object as tr_obj};
    use sui::coin::{Self, Coin};
    use sui::id::{Self, VersionedID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};

    // our Gold coin
    use hero::coin::GOLD;

    const CLASS_COMMON: u8 = 10;
    const CLASS_RARE: u8 = 50;
    const CLASS_EPIC: u8 = 100;

    struct Listing has key {
        id: VersionedID,
        sword: Sword,
        price: u64
    }

    struct Sword has key, store {
        id: VersionedID,
        power: u64,
        item_class: u8,
    }

    struct SwordShop has key {
        id: VersionedID,
        balance: Balance<GOLD>
    }

    fun init(ctx: &mut TxContext) {
        let shop = SwordShop {
            id: tx_context::new_id(ctx),
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

    public entry fun buy_sword<T: key>(
        character: &mut T,
        shop: &mut SwordShop,
        listing: Listing,
        coin: Coin<GOLD>
    ) {
        assert!(coin::value(&coin) == listing.price, 0);

        // keep the money bruh
        let balance = coin::into_balance(coin);
        balance::join(&mut shop.balance, balance);

        let Listing { id, sword, price: _ } = listing;

        id::delete(id);

        tr_obj(sword, character)
    }

    fun list_sword(
        power: u64,
        item_class: u8,
        price: u64,
        ctx: &mut TxContext
    ): Listing {
        Listing {
            id: tx_context::new_id(ctx),
            sword: Sword {
                id: tx_context::new_id(ctx),
                power,
                item_class
            },
            price
        }
    }
}
