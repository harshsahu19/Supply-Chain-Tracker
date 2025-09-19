const hre = require("hardhat");

async function main() {
  const OracleSync = await hre.ethers.getContractFactory("OracleSync");
  const sync = await OracleSync.deploy();
  await sync.deployed();

  console.log("OracleSync deployed to:", sync.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
