import { DiamondFactory } from "../typechain/DiamondFactory";
import { FacetAFactory } from "../typechain/FacetAFactory";
import { FacetBFactory } from "../typechain/FacetBFactory";
import { DeployFunction } from "@foundry/cli/dist/types";

const func: DeployFunction = async ({ deployments, getNamedAccounts }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  // Deploy the diamond contract
  const diamond = await deploy("Diamond", {
    from: deployer,
    log: true,
  });

  // Deploy the facets
  const facetA = await deploy("FacetA", {
    from: deployer,
    log: true,
  });

  const facetB = await deploy("FacetB", {
    from: deployer,
    log: true,
  });

  // Set up diamond cut
  const diamondCut = [
    {
      facetAddress: facetA.address,
      action: 0,
      functionSelectors: FacetAFactory.connect("", "").interface.getSighashes(),
    },
    {
      facetAddress: facetB.address,
      action: 0,
      functionSelectors: FacetBFactory.connect("", "").interface.getSighashes(),
    },
  ];

  // Add the facets to the diamond
  const diamondInstance = DiamondFactory.connect(diamond.address, "");
  await diamondInstance.diamondCut(diamondCut, "", "0x");
};

export default func;
