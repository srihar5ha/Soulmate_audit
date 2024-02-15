## Summary
The system currently allows both a first user (who mints a SoulmateFT) and a new user (without minting a Soulmate NFT) to access the same shared space, i.e., `sharedSpace[0]`. This open access defies the primary purpose of the NFT, which is to govern access and rights to shared space. Further analysis is warranted to ensure the integrity and security of the shared spaces.

## Vulnerability Details
The key issue lies in the implementation of the shared space access. Currently, a new user without possessing the Soulmate NFT can write to and read from the shared space allocated to the first user who minted such an NFT. This effectively makes the unique benefits that come with NFT minting open to all users and negates the exclusivity of access.

```javascript

function test_accessSharedSpace() public{
            vm.prank(soulmate1);
            soulmateContract.writeMessageInSharedSpace("Buy some eggs");
            vm.prank(soulmate2);
            string memory message = soulmateContract.readMessageInSharedSpace();
            console2.log("message read by soulmate2 is",message);
            
            address newuser= makeAddr("user with no NFT");
            vm.prank(newuser);
            string memory newmessage = soulmateContract.readMessageInSharedSpace();
            console2.log("message read by new user is ", newmessage);

            //new user can also write into shared space
            vm.prank(newuser);
            soulmateContract.writeMessageInSharedSpace("I dont have nft");
            
            vm.prank(soulmate2);
            message = soulmateContract.readMessageInSharedSpace();
            console2.log("message read by soulmate2 ",message);
           
            string[4] memory possibleText = [
            "I dont have nft, sweetheart",
            "I dont have nft, darling",
            "I dont have nft, my dear",
            "I dont have nft, honey"
        ];
        bool found;
        for (uint i; i < possibleText.length; i++) {
            if (compare(possibleText[i], message)) {
                found = true;
                break;
            }
        }
        assertTrue(found);

            

    }


```

## Impact
This vulnerability has potential security and privacy implications. Allowing unconstrained access to shared space compromises user exclusivity and privacy. Shared space content could be manipulated by unauthorized parties, leading to potential data integrity issues.

## Tools Used
Manual Review

## Recommendations
Considering potential implications, an immediate review and modification of the contract are suggested:

1. Restricted Access: Implement restricted access for the `writeMessageInSharedSpace` and `readMessageInSharedSpace` functions. Ensure these functions can be called only by the Soulmate NFT holder.

Add the following code in functions `Soulmate:writeMessageInSharedSpace` and `Soulmate:readMessageInSharedSpace`.

```diff 

+  require(soulmateOf[msg.sender]!=address(0), "User does not own soulmate NFT");

```
