// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract TestMillion is ERC1155Supply, Ownable {
    string public name;
    string public symbol;
    uint256 public maxSupply;

    mapping(uint256 => string) public tokenURI;

    constructor() ERC1155("") {
        name = "Test";
        symbol = "Test_test";
        maxSupply = 5000000;
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external onlyOwner {
        require(
            totalSupply(_id) + 1 <= maxSupply,
            "minting another token will exceed max supply"
        );
        _mint(_to, _id, _amount, "");
    }

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                totalSupply(_ids[i]) + _amounts[i] <= maxSupply,
                "minting another token will exceed max supply"
            );
        }
        _mintBatch(_to, _ids, _amounts, "");
    }

    function mintForListOfAddresses(address[] memory _addressArray, uint256 _id)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addressArray.length; i++) {
            require(
                totalSupply(_id) + 1 <= maxSupply,
                "minting another token will exceed max supply"
            );
            _mint(_addressArray[i], _id, 1, "");
        }
    }

    function setURI(uint256 _id, string memory _uri) external onlyOwner {
        tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return tokenURI[_id];
    }
}