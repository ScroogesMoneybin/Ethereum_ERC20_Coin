import { ethers } from "hardhat";

async function main() {
  
  const MinosERC20 = await ethers.getContractFactory("MinosERC20");
  const minosERC20 = await MinosERC20.deploy("Minos","MIN");

  await minosERC20.deployed();

  console.log("Minos ERC20 deployed to:", minosERC20.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
