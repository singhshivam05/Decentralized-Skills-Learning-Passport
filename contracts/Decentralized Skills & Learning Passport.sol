// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// ✅ Use GitHub imports for Remix compatibility
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/utils/Counters.sol";

/**
 * @title SkillChain
 * @dev Decentralized Skills & Learning Passport - NFT-based skill verification system
 */
contract SkillChain is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    enum SkillCategory { Programming, Design, Marketing, DataScience, Blockchain, Other }

    struct SkillNFT {
        string skillName;
        SkillCategory category;
        string issuerName;
        address issuer;
        uint256 completionDate;
        string verificationHash;
        bool isVerified;
    }

    mapping(uint256 => SkillNFT) public skillNFTs;
    mapping(address => uint256[]) public userSkills;
    mapping(address => bool) public verifiedIssuers;
    mapping(string => bool) public usedVerificationHashes;

    event SkillMinted(uint256 indexed tokenId, address indexed recipient, string skillName, SkillCategory category, address indexed issuer);
    event IssuerVerified(address indexed issuer, string issuerName);

    constructor() ERC721("SkillChain", "SKILL") {}

    // 🔹 Core Function 1: Mint Skill NFT
    function mintSkillNFT(
        address recipient,
        string memory skillName,
        SkillCategory category,
        string memory issuerName,
        string memory verificationHash,
        string memory tokenURI_
    ) public {
        require(bytes(skillName).length > 0, "Skill name cannot be empty");
        require(bytes(verificationHash).length > 0, "Verification hash required");
        require(!usedVerificationHashes[verificationHash], "Hash already used");
        require(recipient != address(0), "Invalid recipient");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        skillNFTs[tokenId] = SkillNFT({
            skillName: skillName,
            category: category,
            issuerName: issuerName,
            issuer: msg.sender,
            completionDate: block.timestamp,
            verificationHash: verificationHash,
            isVerified: verifiedIssuers[msg.sender]
        });

        usedVerificationHashes[verificationHash] = true;
        userSkills[recipient].push(tokenId);

        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, tokenURI_);

        emit SkillMinted(tokenId, recipient, skillName, category, msg.sender);
    }

    // 🔹 Core Function 2: Verify Issuer
    function verifyIssuer(address issuer, string memory issuerName) public onlyOwner {
        require(issuer != address(0), "Invalid issuer");
        require(bytes(issuerName).length > 0, "Issuer name required");
        require(!verifiedIssuers[issuer], "Already verified");

        verifiedIssuers[issuer] = true;
        emit IssuerVerified(issuer, issuerName);
    }

    // 🔹 Core Function 3: View user’s skill profile
    function getUserSkillProfile(address user) public view returns (
        uint256[] memory,
        string[] memory,
        SkillCategory[] memory,
        string[] memory,
        uint256[] memory,
        bool[] memory
    ) {
        uint256[] memory userTokens = userSkills[user];
        uint256 count = userTokens.length;

        string[] memory skillNames = new string[](count);
        SkillCategory[] memory categories = new SkillCategory[](count);
        string[] memory issuerNames = new string[](count);
        uint256[] memory dates = new uint256[](count);
        bool[] memory verified = new bool[](count);

        for (uint256 i = 0; i < count; i++) {
            SkillNFT memory skill = skillNFTs[userTokens[i]];
            skillNames[i] = skill.skillName;
            categories[i] = skill.category;
            issuerNames[i] = skill.issuerName;
            dates[i] = skill.completionDate;
            verified[i] = skill.isVerified;
        }

        return (userTokens, skillNames, categories, issuerNames, dates, verified);
    }

    // ✅ Utility Functions

    function isIssuerVerified(address issuer) public view returns (bool) {
        return verifiedIssuers[issuer];
    }

    function getTotalSkillsMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // 🔐 Required overrides

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

