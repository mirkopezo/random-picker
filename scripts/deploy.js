const { ethers } = require("hardhat");

async function main() {
  const RandomPicker = await ethers.getContractFactory("RandomPicker");
  const randomPicker = await RandomPicker.deploy(1519);
  await randomPicker.deployed();

  console.log("Success! RandomPicker was deployed to: ", randomPicker.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
