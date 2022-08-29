pragma solidity 0.8.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./EIP712MetaTransaction.sol";


contract Autograph is EIP712MetaTransaction("autograph","1") {
  event Addautograph(address indexed _TokenContract,uint256 _Tokenid,string AutographUri);
    mapping (address =>mapping(uint256 => string))public autographLayer;
    
   function addAutoGraph(address TokenContract,uint256 Tokenid,string memory autographUri)public {
            if(ERC721(TokenContract).ownerOf(Tokenid)!=msg.sender){
                revert("you need to be the Owner in order to add autograph");
            }
    autographLayer[TokenContract][Tokenid] = autographUri;
    emit Addautograph(TokenContract,Tokenid,autographUri);
    }

    function GetUri(address _TokenContract,uint256 _TokenId) public view returns(string memory){
    return ERC721(_TokenContract).tokenURI(_TokenId);
    }

    function GetAutograph(address _tokenContract,uint256 _tokenId) public view returns(string memory){
        return autographLayer[_tokenContract][_tokenId];
    }
}