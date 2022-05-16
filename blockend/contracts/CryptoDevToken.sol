// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoDevs.sol";

contract CryptoDevToken is ERC20, Ownable {
    // Price of one Crypto Dev token
    uint256 public constant tokenPrice = 0.001 ether;
    // Each NFT would give the owner 10 tokens
    uint256 public constant tokensPerNFT = 10 * 10**18;
    // Maximum total supply is 10000 for Crypto Dev Tokens
    uint256 public constant maxTotalSupply = 10000 * 10**18;
    // CryptoDevsNFT contract instance
    ICryptoDevs CryptoDevsNFT;

    // Mapping to keep record of which tokenIds have been claimed
    mapping(uint256 => bool) public tokenIdsClaimed;

    constructor(address _cryptoDevsContract) ERC20("Crypto Dev Token", "CD") {
        CryptoDevsNFT = ICryptoDevs(_cryptoDevsContract);
    }

    /**
     * @dev Mints `amount` number of CryptoDevTokens
     * @notice `msg.value` should be equal or greater than the tokenPrice * amount
     */
    function mint(uint256 amount) public payable {
        // the value of ETH that should be equal or greater than the tokenPrice * amount
        uint256 _requiredAmount = tokenPrice * amount;
        require(msg.value >= _requiredAmount, "Ether sent is incorrect");
        // total tokens + amount <= 10000, otherwise revert the transaction
        uint256 amountWithDecimals = amount * 10**18;
        require(
            (totalSupply() + amountWithDecimals) <= maxTotalSupply,
            "Exceeds the max total supply available."
        );
        // call the internal _mint function from @openzeppelin
        _mint(msg.sender, amountWithDecimals);
    }

    /**
     * @dev Mints tokens based on the number of NFT's held by the sender
     * @notice balance of Crypto Dev NFT's owned by the sender should be greater than 0
     * Tokens should not have been claimed for all the NFTs owned by the sender
     */
    function claim() public {
        address sender = msg.sender;
        // Get the number of CryptoDev NFT's held by a given sender address
        uint256 balance = CryptoDevsNFT.balanceOf(sender);
        // If owner doesn't own an Crypto Dev NFT, revert transaction
        require(balance > 0, "You don't own any Crypto Dev NFTs");
        // amount keeps track of the number of unclaimed tokenIds
        uint256 amount = 0;
        // loops over the balance and get the tokenId owned by `sender` at a given `index` of its token list.
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = CryptoDevsNFT.tokenOfOwnerByIndex(sender, i);
            // if the tokenId has not been claimed, increase the amount
            if (!tokenIdsClaimed[tokenId]) {
                amount += 1;
                tokenIdsClaimed[tokenId] = true;
            }
        }
        // If all the token Ids have been claimed, revert the transaction;
        require(amount > 0, "You have already claimed all the tokens");
        // call _mint from Openzeppelin and mint (amount * 10) tokens for each NFT owned
        _mint(msg.sender, amount * tokensPerNFT);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
