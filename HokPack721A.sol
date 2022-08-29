// SPDX-License-Identifier: Unlicensed


import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import 'erc721a/contracts/ERC721A.sol';


pragma solidity >=0.8.9 <0.9.0;

contract HoK721A is ERC721A, Ownable, ReentrancyGuard,EIP712 {

  using Strings for uint256;

// ================== Variables Start =======================
 

  // call type hash
  bytes32 constant public MINT_CALL_HASH_TYPE = keccak256("mint(address _rec,uint256 num,uint256 _price)");

  // contract signer address
  address public cSigner=0x6C2bA89f310269E78012AFCF3332144996C0AaF0; 

  // merkletree root hash - p.s set it after deploy from scan
  //bytes32 public merkleRoot;
  //bytes32 public ogmerkleRoot;
  
  // reveal uri - p.s set it in contructor (if sniper proof, else put some dummy text and set the actual revealed uri just before reveal)
  string public uri;
  string public uriSuffix = ".json";

  // hidden uri - replace it with yours
  string public hiddenMetadataUri = "ipfs://Qma1S71PRaQRzXJQZvehx33H3UkbHMWKVak5gMMSs9gVf7/hidden.json";

  // prices - replace it with yours
  uint256 public price = 0.075 ether;
  uint256 public wlprice = 0.07 ether;
  uint256 public genXprice = 0.001 ether;

  // supply - replace it with yours
  uint256 public supplyLimit = 100;

  // max per tx - replace it with yours
  uint256 public maxMintAmountPerTx = 5;
  uint256 public wlmaxMintAmountPerTx = 2;
  uint256 public genXmaxMintAmountPerTx = 1;

  // max per wallet - replace it with yours
  uint256 public maxLimitPerWallet = 2;
  uint256 public wlmaxLimitPerWallet = 2;
  uint256 public genXmaxLimitPerWallet = 2;

  // enabled
  bool public whitelistSale = false;
  bool public publicSale = false;
  bool public genXSale = false;

  // reveal
  bool public revealed = false;

// ================== Variables End =======================  

// ================== Constructor Start =======================

  // Token NAME and SYMBOL - Replace it with yours
  constructor(
    string memory _uri
  ) ERC721A("HoKTest", "HoK") EIP712("HoK", "1")  {
    seturi(_uri);
  }

// ================== Constructor End =======================

// ================== Mint Functions Start =======================

  function GenXMint(uint256 _mintAmount, bytes memory signature) public payable {

    // Verify og requirements
    require(genXSale, 'The GenXSale is paused!');
    bytes32 digest = _hash(msg.sender,1,genXprice);
    require(_verify(digest,signature) == cSigner, "HoK: Invalid signer");

    // Normal requirements 
    require(_mintAmount > 0 && _mintAmount <= genXmaxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(balanceOf(msg.sender) + _mintAmount <= genXmaxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(msg.value >= genXprice * _mintAmount, 'Insufficient funds!');
     
    // Mint
     _safeMint(_msgSender(), _mintAmount);
  }

  function WlMint(uint256 _mintAmount,  bytes memory signature) public payable {

    // Verify wl requirements
    require(whitelistSale, 'The WlSale is paused!');
    bytes32 digest = _hash(msg.sender,2,wlprice);
    require(_verify(digest,signature) == cSigner, "HoK: Invalid signer");


    // Normal requirements 
    require(_mintAmount > 0 && _mintAmount <= wlmaxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(balanceOf(msg.sender) + _mintAmount <= wlmaxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(msg.value >= wlprice * _mintAmount, 'Insufficient funds!');
     
    // Mint
     _safeMint(_msgSender(), _mintAmount);
  }

  function PublicMint(uint256 _mintAmount) public payable {
    
    // Normal requirements 
    require(publicSale, 'The PublicSale is paused!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(balanceOf(msg.sender) + _mintAmount <= maxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(msg.value >= price * _mintAmount, 'Insufficient funds!');
     
    // Mint
     _safeMint(_msgSender(), _mintAmount);
  }  

  function Airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

// ================== Mint Functions End =======================  

// ================== Burn Functions Start ======================= 
    function burnNFTs(uint256[] calldata _ids) external{
        //Require successfull Mint of all NFT
        for(uint i =0;i<_ids.length;i++){
        require(ownerOf(_ids[i])==msg.sender,"NFT is not owned by the user");
            _burn(_ids[i]);
        }
    }
// ================== Burn Functions End ========================

// ================== Set Functions Start =======================

// reveal
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

// uri
  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }
// set Contract Signer
  function setCSigner(address _signer) public onlyOwner{
      cSigner=_signer;
  }

// sales toggle
  function setpublicSale(bool _publicSale) public onlyOwner {
    publicSale = _publicSale;
  }

  function setwlSale(bool _whitelistSale) public onlyOwner {
    whitelistSale = _whitelistSale;
  }

  function setgenXSale(bool _genXSale) public onlyOwner {
    genXSale = _genXSale;
  }

// hash set

// max per tx
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setwlmaxMintAmountPerTx(uint256 _wlmaxMintAmountPerTx) public onlyOwner {
    wlmaxMintAmountPerTx = _wlmaxMintAmountPerTx;
  }

  function setgenXmaxMintAmountPerTx(uint256 _genXmaxMintAmountPerTx) public onlyOwner {
    genXmaxMintAmountPerTx = _genXmaxMintAmountPerTx;
  } 

// pax per wallet
  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
    maxLimitPerWallet = _maxLimitPerWallet;
  }

  function setwlmaxLimitPerWallet(uint256 _wlmaxLimitPerWallet) public onlyOwner {
    wlmaxLimitPerWallet = _wlmaxLimitPerWallet;
  }  

  function setgenXmaxLimitPerWallet(uint256 _genXmaxLimitPerWallet) public onlyOwner {
    genXmaxLimitPerWallet = _genXmaxLimitPerWallet;
  }  

// price
  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setwlprice(uint256 _wlprice) public onlyOwner {
    wlprice = _wlprice;
  }  

  function setgenXprice(uint256 _genXprice) public onlyOwner {
    genXprice = _genXprice;
  }  

// supply limit
  function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
    supplyLimit = _supplyLimit;
  }

// ================== Set Functions End =======================

// ================== Withdraw Function Start =======================
  
  function withdraw() public onlyOwner nonReentrant {
    //owner withdraw 
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

// ================== Withdraw Function End=======================  

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

  function _hash(address receiver, uint256 amount,uint256 _price) internal view returns(bytes32){
        //return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg)));
        return _hashTypedDataV4(keccak256(abi.encode(MINT_CALL_HASH_TYPE, receiver, amount,_price)));

    }

  function _verify(bytes32 digest, bytes memory signature) internal pure  returns(address){
        return ECDSA.recover(digest,signature);
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

  function totalMinted() public view returns(uint256){
    return _totalMinted();
  }

    function ownershipAt(uint256 tokenId) public view  returns (TokenOwnership memory) {
        return _ownershipAt(tokenId);
    }

// ================== Read Functions End =======================  

}