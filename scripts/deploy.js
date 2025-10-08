const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with", deployer.address);

  const DiskRegistry = await hre.ethers.getContractFactory("DiskRegistry");
  const registry = await DiskRegistry.deploy();
  await registry.deployed();
  console.log("DiskRegistry:", registry.address);

  const DiskMarketplace = await hre.ethers.getContractFactory("DiskMarketplace");
  const marketplace = await DiskMarketplace.deploy(registry.address);
  await marketplace.deployed();
  console.log("DiskMarketplace:", marketplace.address);

  const FileRegistry = await hre.ethers.getContractFactory("FileRegistry");
  const fileRegistry = await FileRegistry.deploy(marketplace.address);
  await fileRegistry.deployed();
  console.log("FileRegistry:", fileRegistry.address);

  const tx = await marketplace.setFileRegistry(fileRegistry.address);
  await tx.wait();
  console.log("FileRegistry set in marketplace");
}

main().catch((err) => { console.error(err); process.exit(1); });
