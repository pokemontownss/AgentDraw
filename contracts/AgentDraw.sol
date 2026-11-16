// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAgentId {
    function balanceOf(address account) external view returns (uint256);
}

/// @title AgentDraw (DRAW) — pixel art drawn live by AI agents on BNB Chain.
/// @notice ERC-721 mint contract matching the public site spec (agentdraw.click):
/// - MAX_SUPPLY 1,444 = 1,222 Free Draw + 222 Instant (Paid) Draw, two
///   SEPARATE pools with separate counters. Neither pool ever blocks the other.
/// - NO PHASES: one switch (mintOpen) opens Free and Paid at the same moment.
/// - Free Draw: 0 BNB, max 2 per wallet, Binance Agent ID holders only
///   (registry AGENT_ID_REGISTRY, balanceOf > 0, checked on-chain at mint).
///   One global queue: a free draw can only happen at least FREE_COOLDOWN
///   (90 seconds) after the previous successful free draw by anyone.
///   Free draws roll DOODLE 70% / PIXEL 30% only — never a rare tier.
/// - Instant Draw: payable, open to EVERY wallet from the first moment mint
///   opens — including Binance Agent ID holders, who may use both paths.
///   It never checks for an Agent ID, never looks at the Free pool and is
///   never limited by the caller's free draws. The only gates are: mint open,
///   the Paid pool not sold out, and msg.value == currentPrice().
/// - Price: starts at BASE_PRICE = 0.0012 BNB and steps up by PRICE_STEP =
///   0.0003 BNB for every 500 TOTAL minted (both pools count toward the step):
///   currentPrice = BASE_PRICE + (totalMinted / 500) * PRICE_STEP.
/// - Tier is rolled inside the mint transaction itself (one call for wallet
///   users and AI agents alike) and stored per token. Paid odds:
///   DOODLE 27 / PIXEL 25 / NEON 20 / RARE 12 / GLITCH 10 / GOLD FOIL 5 /
///   MASTERPIECE 1 (percent). The roll is pseudo-random from block data
///   (block.prevrandao, timestamp, minter, tokenId) — suitable for this
///   collection's scale; it is not VRF.
/// - Token IDs come from ONE counter in mint order. There is no pre-numbering
///   and no number range per pool.
/// - tokenURI is by style tier, not by number: baseURI + one of
///   doodle.json / pixel.json / neon.json / rare.json / glitch.json /
///   gold-foil.json / masterpiece.json, chosen from the tier stored at mint.
/// - Fees are HELD in the contract; the owner collects them with withdraw().
/// - mintOpen defaults FALSE: the owner opens mint when ready.
contract AgentDraw is ERC721, Ownable {
    uint256 public constant MAX_SUPPLY = 1444;
    uint256 public constant FREE_LIMIT = 1222;
    uint256 public constant PAID_LIMIT = 222;
    uint256 public constant FREE_MAX_PER_WALLET = 2;
    uint256 public constant BASE_PRICE = 1200000000000000; // 0.0012 BNB
    uint256 public constant PRICE_STEP = 300000000000000; // +0.0003 BNB
    uint256 public constant PRICE_STEP_EVERY = 500; // total minted per step
    uint256 public constant FREE_COOLDOWN = 90; // seconds, global free queue

    /// @notice Binance Agent ID registry on BNB Chain. Read-only check; the
    /// registry itself is not owned or controlled by this contract.
    address public constant AGENT_ID_REGISTRY = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    // Draw kinds recorded in the DrawMinted event.
    uint8 public constant KIND_FREE = 0;
    uint8 public constant KIND_PAID = 1;

    /// @notice Style tiers, in the order of the site's Style Codex.
    enum Tier {
        DOODLE,
        PIXEL,
        NEON,
        RARE,
        GLITCH,
        GOLD_FOIL,
        MASTERPIECE
    }

    string public baseURI;
    bool public mintOpen;
    uint256 public totalMinted;
    uint256 public freeMinted;
    uint256 public paidMinted;
    uint256 public lastFreeDrawAt;
    mapping(address => uint256) public freeCountBy;
    mapping(address => uint256) public paidCountBy;
    mapping(uint256 => Tier) public tokenTier;

    event BaseURISet(string baseURI);
    event DrawMinted(address indexed minter, uint256 indexed tokenId, uint8 kind, uint8 tier);

    constructor(string memory initialBaseURI) ERC721("AgentDraw", "DRAW") Ownable(msg.sender) {
        baseURI = initialBaseURI;
    }

    /// @notice True when `wallet` holds at least one Binance Agent ID.
    function hasAgentId(address wallet) public view returns (bool) {
        return IAgentId(AGENT_ID_REGISTRY).balanceOf(wallet) > 0;
    }

    function freeRemaining() public view returns (uint256) {
        return FREE_LIMIT - freeMinted;
    }

    function paidRemaining() public view returns (uint256) {
        return PAID_LIMIT - paidMinted;
    }

    /// @notice Current Instant Draw price in wei. Steps up by PRICE_STEP for
    /// every PRICE_STEP_EVERY total minted across both pools.
    function currentPrice() public view returns (uint256) {
        return BASE_PRICE + (totalMinted / PRICE_STEP_EVERY) * PRICE_STEP;
    }

    /// @notice Timestamp when the global free-draw queue opens again
    /// (0 before the first free draw ever).
    function freeDrawReadyAt() public view returns (uint256) {
        if (lastFreeDrawAt == 0) return 0;
        return lastFreeDrawAt + FREE_COOLDOWN;
    }

    /// @notice Seconds until the next free draw can happen (0 = ready now).
    function freeCooldownRemaining() public view returns (uint256) {
        uint256 ready = freeDrawReadyAt();
        if (ready == 0 || block.timestamp >= ready) return 0;
        return ready - block.timestamp;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURISet(newBaseURI);
    }

    /// @notice The single mint switch: opening mint opens Free and Paid together.
    function setMintOpen(bool _open) external onlyOwner {
        mintOpen = _open;
    }

    function withdraw() external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "empty");
        (bool ok, ) = owner().call{value: bal}("");
        require(ok, "withdraw failed");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _tierSlug(Tier tier) internal pure returns (string memory) {
        if (tier == Tier.PIXEL) return "pixel";
        if (tier == Tier.NEON) return "neon";
        if (tier == Tier.RARE) return "rare";
        if (tier == Tier.GLITCH) return "glitch";
        if (tier == Tier.GOLD_FOIL) return "gold-foil";
        if (tier == Tier.MASTERPIECE) return "masterpiece";
        return "doodle";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return string(abi.encodePacked(_baseURI(), _tierSlug(tokenTier[tokenId]), ".json"));
    }

    /// @notice Pseudo-random roll seed, same approach as the owner's other
    /// collections: block data mixed with the minter and the token id.
    function _roll(uint256 tokenId) internal view returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, msg.sender, tokenId))) % 100;
    }

    /// @notice Free Draw — Binance Agent ID holders only, max 2 per wallet,
    /// one global 90-second queue. Rolls DOODLE 70% / PIXEL 30% only.
    function freeDraw() external {
        require(mintOpen, "mint closed");
        require(hasAgentId(msg.sender), "needs Agent ID");
        require(freeCountBy[msg.sender] < FREE_MAX_PER_WALLET, "max 2 free per wallet");
        require(freeMinted < FREE_LIMIT, "free pool sold out");
        require(block.timestamp >= lastFreeDrawAt + FREE_COOLDOWN, "free queue cooling down");
        lastFreeDrawAt = block.timestamp;
        totalMinted += 1;
        freeMinted += 1;
        freeCountBy[msg.sender] += 1;
        Tier tier = _roll(totalMinted) < 70 ? Tier.DOODLE : Tier.PIXEL;
        tokenTier[totalMinted] = tier;
        _safeMint(msg.sender, totalMinted);
        emit DrawMinted(msg.sender, totalMinted, KIND_FREE, uint8(tier));
    }

    /// @notice Instant Draw — open to every wallet, Agent ID holders included.
    /// No Agent ID check, no Free-pool check, no free-usage check, no phase:
    /// mint open + Paid pool remaining + the exact current price are the
    /// only gates. Tier rolled inside this same transaction.
    function instantDraw() external payable {
        require(mintOpen, "mint closed");
        require(paidMinted < PAID_LIMIT, "paid pool sold out");
        require(msg.value == currentPrice(), "wrong fee");
        totalMinted += 1;
        paidMinted += 1;
        paidCountBy[msg.sender] += 1;
        uint256 r = _roll(totalMinted);
        Tier tier;
        if (r < 27) tier = Tier.DOODLE;
        else if (r < 52) tier = Tier.PIXEL;
        else if (r < 72) tier = Tier.NEON;
        else if (r < 84) tier = Tier.RARE;
        else if (r < 94) tier = Tier.GLITCH;
        else if (r < 99) tier = Tier.GOLD_FOIL;
        else tier = Tier.MASTERPIECE;
        tokenTier[totalMinted] = tier;
        _safeMint(msg.sender, totalMinted);
        emit DrawMinted(msg.sender, totalMinted, KIND_PAID, uint8(tier));
    }
}
