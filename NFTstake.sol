// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTStake is ERC20, Ownable, ERC721Holder {
    IERC721 public nft;

    struct nftStakeData {
        address tokenOwner;
        uint256 stakedAt;
        uint256 stakeEndTime;
        uint256 stakedDuration;
    }

    uint256 public rewardRate1Month = 5;
    uint256 public rewardRate6Months = 10;
    uint256 public rewardRate12Months = 15;


    // tokenId => address & stakeTime
    mapping(uint256 => nftStakeData) NFTstakeData;

    constructor(address _nft) ERC20("MyToken", "MTK") {
        nft = IERC721(_nft);
    }

    
    function calculateReward(uint256 tokenId) private view returns (uint256) {
        uint256 duration = NFTstakeData[tokenId].stakedDuration;
        uint256 rewardRate;
        if(duration == 1){
            rewardRate = rewardRate1Month;
        } if(duration == 6){
            rewardRate = rewardRate6Months;
        } if(duration == 12 || duration > 12){
            rewardRate = rewardRate12Months;
        }

        uint256 elapsed = block.timestamp - NFTstakeData[tokenId].stakedAt;
        uint256 reward = (elapsed / 1 days) * rewardRate / 365;
        return reward;
    }

    function stakeToken(uint256 tokenId, uint256 duration) external {
        require(duration == 1 || duration == 6 || duration == 12, "Invalid staking duration.");
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        NFTstakeData[tokenId].tokenOwner = msg.sender;
        NFTstakeData[tokenId].stakedAt = block.timestamp;
        NFTstakeData[tokenId].stakeEndTime = block.timestamp + duration * 30 days;
        NFTstakeData[tokenId].stakedDuration = duration;
    }

    function unStakeToken(uint256 tokenId) public {
        require(
            NFTstakeData[tokenId].stakeEndTime < block.timestamp &&
                NFTstakeData[tokenId].tokenOwner == msg.sender,
            "You can't unstake it before the end of duration"
        );
        uint256 reward = calculateReward(tokenId);
        _mint(msg.sender, reward);
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        delete NFTstakeData[tokenId];
    }
}
