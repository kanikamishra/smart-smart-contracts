// SPDX-License-Identifier: Unlicensed

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'erc721a/contracts/ERC721A.sol';


pragma solidity >=0.8.9 <0.9.0;

contract HoKFaction721A is ERC721A, AccessControl {
  using Strings for uint256;

// ================== Variables Start =======================
 
  //Declare Admin role
  //bytes32 public constant ADMIN = keccak256("ADMIN_ROLE");
  //Declare minter role
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  // merkletree root hash - p.s set it after deploy from scan
  //bytes32 public merkleRoot;
  //bytes32 public ogmerkleRoot;
  
  // reveal uri - p.s set it in contructor (if sniper proof, else put some dummy text and set the actual revealed uri just before reveal)
  string public uri;
  string public uriSuffix = ".json";

  // hidden uri - replace it with yours
  string public hiddenMetadataUri = "ipfs://Qma1S71PRaQRzXJQZvehx33H3UkbHMWKVak5gMMSs9gVf7/hidden.json";
/*
  // prices - replace it with yours
  uint256 public price = 0.075 ether;
  uint256 public wlprice = 0.07 ether;
  uint256 public genXprice = 0.001 ether;
*/
  // supply - replace it with yours
  uint256 public supplyLimit = 100;
  

  // max per tx - replace it with yours
  uint256 public maxMintAmountPerTx = 5;

  // reveal
  bool public revealed = false;

// ================== Variables End =======================  

// ================== Constructor Start =======================

  // Token NAME and SYMBOL - Replace it with yours
  constructor(

  ) ERC721A("HoKFactionTest", "HoKFact")   {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

// ================== Constructor End =======================

// ================== Mint Functions Start =======================
 
  function Mint(uint256 _mintAmount,address _rec) public onlyRole(MINTER_ROLE) {
    
    // Normal requirements 
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
     
    // Mint
     _safeMint(_rec, _mintAmount);
  } 


// ================== Mint Functions End =======================  


// ================== Set Functions Start =======================

// reveal
  function setRevealed(bool _state) public onlyRole(DEFAULT_ADMIN_ROLE) {
    revealed = _state;
  }

// uri
  function seturi(string memory _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uri = _uri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uriSuffix = _uriSuffix;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

// max per tx
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyRole(DEFAULT_ADMIN_ROLE) {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }
 
// supply limit
  function setsupplyLimit(uint256 _supplyLimit) public onlyRole(DEFAULT_ADMIN_ROLE) {
    supplyLimit = _supplyLimit;
  }


// ================== Set Functions End =======================

// ================== Read Functions Start =======================

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= supplyLimit) {
      TokenOwnership memory ownership = _ownershipAt(currentTokenId);

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }



  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

// ================== Read Functions End =======================  

// ================== Override Function start =======================  
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    // The interface IDs are constants representing the first 4 bytes
    // of the XOR of all function selectors in the interface.
    // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
    // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
    return
        interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
        interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
        interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }
// ================== Override Functions End =======================  
}