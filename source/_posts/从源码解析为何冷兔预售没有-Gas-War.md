---
title: 从源码解析为何冷兔预售没有 Gas War
date: 2022-01-17 20:29:55
tags:
---

昨日冷兔预售，在成为国产 NFT 之光冲上 OpenSea 时段榜一之外，不知大家是否察觉，整个预售过程，Gas 费并没有明显暴涨：

![2022/1/16 Gas](https://static.cnodejs.org/FvOh7fhh6cMazwGbNHLHRWgxN3n5)

可以看到，整个下午的 Gas Price 在图中并没有明显尖刺。在项目如此之热的情况下，冷兔是如何做到的呢？让我们从它的[合约代码](https://etherscan.io/address/0x534d37c630b7e4d2a6c1e064f3a2632739e9ee04#code#F13#L1)来看：

```sol
// XRC.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";

contract XRC is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    // ...

    function presaleMint(
        uint256 amount,
        string calldata salt,
        bytes calldata token
    ) external payable {
        require(status == Status.PreSale, "XRC: Presale is not active.");
        require(
            tx.origin == msg.sender,
            "XRC: contract is not allowed to mint."
        );
        require(_verify(_hash(salt, msg.sender), token), "XRC: Invalid token.");
        require(
            numberMinted(msg.sender) + amount <= maxMint,
            "XRC: Max mint amount per wallet exceeded."
        );
        require(
            totalSupply() + amount + reserveAmount - tokensReserved <=
                collectionSize,
            "XRC: Max supply exceeded."
        );

        _safeMint(msg.sender, amount);
        refundIfOver(PRICE * amount);

        emit Minted(msg.sender, amount);
    }

    // ...
}
```

可以看到，整个合约多重继承了 Ownable，ReentrancyGuard 和 ERC721A 。前两个合约都是来自大家常用的[OpenZeppelin](https://docs.openzeppelin.com/)，分别用于控制部分关键函数的调用权限和防止重入攻击，而第三个继承的合约： ERC721A ，即是 `presaleMint` 函数的关键部分 `_safeMint(msg.sender, amount);` 的实现之处。

其实，ERC721A 也是对 @openzeppelin/IERC721 的一个实现，相比于 OpenZeppelin 自带的实现，优化了单次 mint 时的 Gas 开销。在 5 天前的 Azuki 项目 mint 时，首次使用。我们在 [Azuki 的合约](https://etherscan.io/address/0xed5af388653567af2f388e6224dc7c4b3241c544#code#F4#L5)中也能看到它：

```sol
// Azuki.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Azuki is Ownable, ERC721A, ReentrancyGuard {
  // ...
  function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey)
    external
    payable
    callerIsUser
  {
    // ...
    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * quantity);
  }
}
```

那么 ERC721A 相比大家常用的 @openzeppelin/ERC721Enumerable ，具体在哪里做了优化呢？让我们对比它们的源码来一探究竟。

## Storage 存储空间的优化

我们知道，以太坊中的 storage 存储是昂贵的，并且，在以太坊中，调用不修改合约状态的只读函数（view / pure）是免费的。而在 @openzeppelin/ERC721Enumerable 实现中，为了方便读取 NFT 的所有者信息，做了许多冗余的元数据存储，作为代价，在 mint 函数内，则需要额外的开销来存储这些信息。而 ERC721A 实现则相反，将所占的必须存储压缩到了最小，这样虽然增加了读取时的复杂度，但是读取是免费的。

```sol
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    // ...
}
```

- _ownedTokens 是钱包地址到另一个 map 的映射，另一个 map 表示用户拥有的第 N 个该 NFT 的 ID 。即 `_ownedTokens['addr1'][0] = 201` 表示，addr1 这个钱包地址，拥有的第一个该 NFT 的 ID 是 201 。
- _ownedTokensIndex 保存了该 NFT ID 到用户拥有索引的映射。即 `_ownedTokensIndex[201] = 0` 表示 ID 为 201 的该 NFT 是所属用户的拥有列表中的第一个。
- _allTokens 表示了所以被 mint 出来的该 NFT 的 ID 列表。
- _allTokensIndex 表示了具体某个 ID 的 NFT 在 _allTokens 列表中的位置。

我们可以看到上面四个存储的数据中，有两个（*Index）数据都是另两个数据的索引，若读取开销为免费的话，则它们（*Index）是冗余的，可以通过遍历来实现同样的效果。

而在 ERC721A 的实现中，的确去除了那两个冗余索引：

```sol
contract ERC721A is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
  struct TokenOwnership {
      address addr;
      uint64 startTimestamp;
  }

  struct AddressData {
      uint128 balance;
      uint128 numberMinted;
  }

  mapping(uint256 => TokenOwnership) private _ownerships;

  mapping(address => AddressData) private _addressData;

  // ...
}
```

可以看到，仅做了 ID => 钱包地址，钱包地址 => 所有数量，这两个映射。

## 批量 Mint

在 @openzeppelin/ERC721Enumerable 实现中 mint 只支持单个，一次 mint 多个需要 NFT 合约自行通过多次调用来实现：

```sol
// ERC721Enumerable 使用过的是 @openzeppelin/ERC721 中的 _safeMint
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
  // ...
  function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }
  // ...
}
```

这就意味着，如果一次 mint N 个，合约中的元数据会被进行 N 次改写，举个例子，上文中的 _allTokens 会被在尾部进行 N 次 push。而 ERC721A ，则支持批量 Mint ，并且通过其特制的数据结构（后文会细述），只需要对元数据进行一次修改：

```sol
contract ERC721A is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
  function _safeMint(
        address to,
        uint256 quantity, // 支持批量 mint
        bytes memory _data
    ) internal {
        // ...
    }
}
```

## 批量 Mint 仅需对元数据进行一次修改

ERC721A 使用的数据结构假设每个用户所 mint 的 ID 是连续的。所以每次批量 mint ，都只会记录一下用户的第一个 mint 出来的该 NFT ID ，以及当前使用的 NFT 计数即可。举个例子：有 A， B，C 三个地址分别进了 mint 后，A 拥有 101，102，103 号 NFT，B 用户 104，105号 NFT，C 只拥有 106 号 NFT，那么储存的数据便是

#101 #102 #103 #104 #105 #106
A              B         C

当前已使用 NFT 计数为 106 。

位置 102，103，并不会存储任何数据，但是之前的前提，用户的 mint 是连续的，我们也可以知道它们的所有者。

```sol
contract ERC721A is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
  function _safeMint(
        address to,
        uint256 quantity, // 支持批量 mint
        bytes memory _data
    ) internal {
        uint256 startTokenId = currentIndex;
        // ...

        // 1）这里仅记录了第一个 ID
        _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            emit Transfer(address(0), to, updatedIndex);
            // ...
            updatedIndex++;
        }

        // 2）更新了计数
        currentIndex = updatedIndex;
    }
}
```

这样一来，ERC721A 做到了就把对 storage 的写入从 O(N) 优化到了 O(1) 。单次 mint 的数量越多，优化效果则越明显。

## 实验效果

根据 Azuki 官方给出的试验效果，同样印证了我们刚才得出的“把对 storage 的写入从 O(N) 优化到了 O(1)”的结论：

![Gas Statistics](https://static.cnodejs.org/FulBxjDixiGJTz1ixODdcC3mkXP7)
