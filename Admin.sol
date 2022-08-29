// SPDX-License-Identifier: Unlicensed


import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

pragma solidity >=0.8.9 <0.9.0;
/**
(holo = 100, gold = 300, silver = 600)
---------
-----------C---F---M
H_A(50)=>--2---1---1 | 4
H_A(50)=>--1---2---1 | 4
G_(300)=>--1---1---1 | 3
SA(300)=>--1---0---1 | 2
SB(300)=>--0---1---1 | 1

 */
interface IAdmin {
    function Mint(uint256 _mintAmount,address _rec) external;   
}
interface IHokPack{
        struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }
    function ownershipAt(uint256 tokenId) external view returns(TokenOwnership memory);
}
contract Admin is Ownable,EIP712{



// ================== Variables Start =======================
    //Declare Call hash variable
    bytes32 constant public MINT_CALL_HASH_TYPE = keccak256("mint(address _rec,uint256 _tokenId,uint256 _type)");//type (0,1,2)=>(H,G,S)
    // contract signer address
    address public cSigner=0x6C2bA89f310269E78012AFCF3332144996C0AaF0; 

    //Contract Addresses
    address public Character;
    address public Faction;
    address public Merch;
    //Struct 
    struct Pack{
        uint256 holoA;
        uint256 holoB;
        uint256 gold;
        uint256 silverA;
        uint256 silverB;
    }


    Pack public nftpack;
    mapping(uint256 => bool) public isClaimed;


// ================== Variables End =======================


// ================== Constructor Start =======================

    constructor()  EIP712("Admin", "1") {}

// ================== Constructor END =======================

// ================== Mint Start ===========================
    function HoloPack(uint8 _type,address _con,uint256 _tid,bytes memory signature) public {

        // Verify  requirements
        (address _a,bool _b)=readPackTokenIdState(_con,_tid);
        require(_b && !isClaimed[_tid],'Burn the Pack to claim.');
        bytes32 digest = _hash(_a,_tid,0);
        require(_verify(digest,signature) == cSigner, "HoK: Invalid signer");

        if(_type==0){
            isClaimed[_tid] = true;
            nftpack.holoA = nftpack.holoA+1;
            require(_mintBundles(2,1,1,_a),'Unsuccessful to Mint the bundle');
        
        }else if(_type==1){
            isClaimed[_tid] = true;
            nftpack.holoB = nftpack.holoB+1;
            require(_mintBundles(1,2,1,_a),'Unsuccessful to Mint the bundle');  
        }
    }
    function GoldPack(address _con,uint256 _tid,bytes memory signature) public {
        (address _a,bool _b)=readPackTokenIdState(_con,_tid);
        require(_b && !isClaimed[_tid],'Burn the Pack to claim.');
        bytes32 digest = _hash(_a,_tid,0);
        require(_verify(digest,signature) == cSigner, "HoK: Invalid signer");
        isClaimed[_tid] = true;
        nftpack.gold = nftpack.gold+1;
        require(_mintBundles(1,1,1,_a),'Unsuccessful to Mint the bundle');
    
    }
    function SilverPack(uint8 _type,address _con,uint256 _tid,bytes memory signature) public {
        (address _a,bool _b)=readPackTokenIdState(_con,_tid);
        require(_b && !isClaimed[_tid],'Burn the Pack to claim.');
        bytes32 digest = _hash(_a,_tid,0);
        require(_verify(digest,signature) == cSigner, "HoK: Invalid signer");

        if(_type==0){
            isClaimed[_tid] = true;
            nftpack.silverB = nftpack.silverB+1;
            require(_mintBundles(1,0,1,_a),'Unsuccessful to Mint the bundle');
            nftpack.silverA = nftpack.silverA+1;
        }else if(_type==1){
            isClaimed[_tid] = true;
            nftpack.silverB = nftpack.silverB+1;
            require(_mintBundles(0,1,1,_a),'Unsuccessful to Mint the bundle');
            
        }
    }
// ================== Mint End ==============================

// ================== Set Function Start ======================

// set Contract addresses of Character, Faction and Merch
    function setContractAddrs(address _c,address _f,address _m) public onlyOwner {
        require(_c != address(0) &&_f != address(0)&&_m != address(0),'Invalid input');
        Character=_c;
        Faction =_f;
        Merch =_m;
    }
// set Contract Signer
    function setCSigner(address _signer) public onlyOwner{
      cSigner=_signer;
  }
// ================== Set Function End ======================

// ================== Internal Start ========================
    function _mintBundles(uint256 _c,uint256 _f,uint256 _m,address _rec) virtual internal returns(bool) {
        
        IAdmin(Character).Mint(_c, _rec);
        IAdmin(Faction).Mint(_f, _rec);
        IAdmin(Merch).Mint(_m, _rec);
        return true;
    }
    function readPackTokenIdState(address _con,uint256 _tid) internal view  returns(address,bool){
        IHokPack.TokenOwnership memory ownership = IHokPack(_con).ownershipAt(_tid);
        return (ownership.addr,ownership.burned);

    }

// ================== Internal End ==========================
// ================== Read State Start ======================

    function _hash(address receiver, uint256 amount,uint256 _price) public view returns(bytes32){
        //return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg)));
        return _hashTypedDataV4(keccak256(abi.encode(MINT_CALL_HASH_TYPE, receiver, amount,_price)));

    }

    function _verify(bytes32 digest, bytes memory signature) public pure  returns(address){
        return ECDSA.recover(digest,signature);
    }

// ================== Read Start End =======================

    


}