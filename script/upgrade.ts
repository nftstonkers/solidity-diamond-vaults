import { ethers, upgrades } from "foundry";

async function main() {
  const [deployer] = await ethers.getSigners();

  // Deploy V1
  const DiamondVaultFacetV1Factory = await ethers.getContractFactory("DiamondVaultFacetV1");
  const diamondVaultFacetV1 = await upgrades.deployProxy(DiamondVaultFacetV1Factory);
  await diamondVaultFacetV1.deployed();
  console.log("DiamondVaultFacetV1 deployed at:", diamondVaultFacetV1.address);

  // Upgrade to V2
  const DiamondVaultFacetV2Factory = await ethers.getContractFactory("DiamondVaultFacetV2");
  const diamondVaultFacetV2 = await upgrades.upgradeProxy(diamondVaultFacetV1.address, DiamondVaultFacetV2Factory);
  console.log("DiamondVaultFacetV2 upgraded at:", diamondVaultFacetV2.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
