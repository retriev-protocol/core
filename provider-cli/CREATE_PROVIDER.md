# Retriev Protocol - Create your own provider

This provider CLI is a very basic implementation of a provider. It allows you to register as provider, connect to your local IPFS instance and start automatically accepting deals.

You can of course create your own provider, since the provider, at the protocol level, have to fullfill some basic requirements:

1) Be registered on the smart contract as a provider with a valid endpoint
2) Have a valid IPFS endpoint where referees and clients can retrieve the data
3) Listen to the deal proposal event to accept the proposed deals
4) Register your strategy on the API (strategy itself is offchain)

## Overview of the deal flow

It worth to give some basic overview of the deal flow, so let's dive into it.

1) A client create a deal proposal on the smart contract by adding some informations like data_uri, duration, collateral and providers.
2) The smart contract emit a deal proposal event with the deal informations.
3) The provider listen to the deal proposal event and accept the deal proposal if the proposal matches the provider's strategy.
4) The provider send a deal acceptance to the smart contract.
5) The smart contract emit a deal acceptance event.
6) At the end of the deal duration the client can withdraw the funds from the smart contract.

Of course starting from the deal acceptance event the client knows that you as provider can give him the file, since you accepted the deal and added a collateral as a guarantee of the successful retrieval over the deal duration.

At this point you have to be sure that the file is available on your specified endpoint, otherwise the client can appeal the network and you will lose your collateral.

## How to register as provider

### Send a transaction to the smart contract

The first step is to register inside the contract, this is the function to call:
```
function setProviderStatus(address _provider, bool _state, string memory _endpoint)
```

This function will allow you to register as provider on the smart contract, so the clients can see you as a valid provider and propose deals to you. The `_endpoint` is the endpoint where the client will retrieve the data, we expect something like `https://ipfs.awesome-provider.com/ipfs/`.

You can set the status to `true` or `false`, this is useful if you want to temporarly stop your provider, or unsubscribe from the protocol.

### Register your strategy on the API

The second step is to register a strategy on the API, so you have to send a `POST` request to the API with the following informations:

```
{
strategy: {
    min_price: <YOUR_MIN_PRICE>,
    max_size: <YOUR_MAX_SIZE>,
    max_collateral_multiplier: <YOUR_MAX_COLLATERAL_MULTIPLIER>,
    max_duration: <YOUR_MAX_DURATION>,
},
    endpoint: <YOUR_ENDPOINT>,
    address: <YOUR_ADDRESS>,
    signature: <YOUR_SIGNATURE>,
}
```

The `address` is your wallet address, the `signature` is the signature of this message:
```
Store <YOUR_ADDRESS> strategy.
```

Since we said that the strategy is offchain, you theoretically can also signal the strategy using other methods, but this is the most simple one, since it will subscribe you also inside our dApp.

Our endpoints are:
- `api-sepolia.retr.dev`: for the Base Sepolia testnet
- `api-fevm-mainnet.retr.dev`: for the Filecoin FEVM mainnet

## Listen to deal proposal event

The last step is to listen to the deal proposal event, which is the following:

```
event DealProposalCreated(
    uint256 index,
    address[] providers,
    string data_uri,
    address[] appeal_addresses
);
```

As you can see you have the `index`, which is needed to accept it, an array of `providers`, which is an array of the providers that the client selected, the `data_uri`, which is the URI of the data that the client want to store, and the `appeal_addresses`, which is an array of the addresses that will be used to appeal the deal in case of failure.

You can check our code [here](https://github.com/retriev-protocol/core/blob/main/provider-cli/src/libs/fn.js#L884) for the implementation using `ethers`. Of course you can use any library you want, or any other language you want.

## Deal details

Before accepting the deal you have to [deposit the collateral](##Deposit-and-withdraw-funds), if the required collateral is more than `0` of course. To get the deal details you can read the `deals` mapping, by using the `deal_index` returned by the `DealProposalCreated` event.

This is the structure of the `deals` mapping:
```
struct Deal {
    // subject of the deal
    string data_uri;
    // Timestamp request
    uint256 timestamp_request;
    // Starting timestamp
    uint256 timestamp_start;
    // Duration of deal expressed in seconds
    uint256 duration;
    // Amount in wei paid for the deal
    uint256 value;
    // Amount in wei needed to accept the deal
    uint256 collateral;
    // Address of provider
    mapping(address => bool) providers;
    // Address of owner
    address owner;
    // Describe if deal is canceled or not
    bool canceled;
    // Addresses authorized to create appeals
    mapping(address => bool) appeal_addresses;
}
```
Just a quick note on the deal, you have to check also the `proposal_timeout` variable, which is `86_400` seconds (1 day) by default, to be sure that the deal is still valid. After this time the deal can't be accepted anymore.

## Accept a deal

To accept the deal you have to call the following function:

```
function acceptDealProposal(uint256 deal_index)
```

As you can see you have to pass the `deal_index` to the function, which is the index of the deal proposal event.

## Redeem a deal

When the deal duration ends, you have to redeem the deal to get your collateral and the payment from the client.

You can call the following function:

```
function redeemDeal(uint256 deal_index)
```

As you can see you have to pass the `deal_index` to the function, which is the index of the deal proposal event. 

## Deposit and withdraw funds

In order to deposit and withdraw funds you have to call the following functions:
```
function depositToVault() payable
```
The first one needs a `msg.value` and will deposit the funds into your vault. These funds will be used to pay the collateral of the deals you accept.

```
function withdrawFromVault(uint256 amount)
```
This function will withdraw the specified amount from your vault.


# Conclusions

With that said you now have all the informations to create your own provider and start accepting deals. As you can see in this description we don't have any requirement for the storage itself of the data, since we expect the providers to use their own storage to store the data and just give the possibility to the clients to retrieve the data from the providers.

If you have any questions, please reach out to us opening an issue on [Github](https://github.com/retriev-protocol/core).