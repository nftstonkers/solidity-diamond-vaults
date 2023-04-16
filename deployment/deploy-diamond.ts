// deploy.ts
import { ethers } from 'ethers';
import * as dotenv from 'dotenv';
import * as Diamond from '../out/DiamondVault.sol/DiamondVault.json'
import * as DiamondCutFacet from '../out/DiamondCutVaultFacet.sol/DiamontCutVaultFacet.json';
import * as DiamondLoupeFacet from '../out/DiamondLoupeVaultFacet.sol/DiamondLoupeVaultFacet.json';
import * as OwnershipFacet from '../out/OwnershipVaultFacet.sol/OwnershipVaultFacet.json';
import * as DiamondVaultFacetV1 from '../out/DiamondVaultFacetV1.sol/DiamondVaultFacetV1.json'

dotenv.config();

const createDiamondCut = (cut: [string, string[]][]) => {
    return cut.map(([address, functionId]) => [
        address,
        0,
        functionId.map(id => ethers.utils.hexDataSlice(id, 0, 4)),
    ]);
};

const addDiamondCuts = async (diamondAddress: string, diamondCut: [string, string[]][], deployer: ethers.Wallet) => {
    const diamond = new ethers.Contract(diamondAddress, Diamond.abi, deployer);
    const diamondCutFacet = new ethers.Contract(diamondAddress, DiamondCutFacet.abi, deployer);

    const formattedDiamondCut = createDiamondCut(diamondCut);

    const data = diamondCutFacet.interface.encodeFunctionData('diamondCut', [formattedDiamondCut, ethers.constants.AddressZero, '0x']);


    const tx = {
        to: diamondAddress,
        data: data,
    };

    const gasLimit = await ethers.provider.estimateGas(tx);
    const gasPrice = await provider.getGasPrice();

    const signedTx = await deployer.signTransaction({
        ...tx,
        gasLimit: gasLimit.toHexString(),
        gasPrice: gasPrice.toHexString(),
    });

    const txResponse = await provider.send('eth_sendRawTransaction', [signedTx]);

    const receipt = await txResponse.wait();

    console.log('Diamond cuts added successfully');

    console.log('Diamond cuts added successfully');
};



const deployDiamond = async () => {
    const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_ENDPOINT, {
        name: 'unknown',
        chainId: parseInt(process.env.CHAIN_ID ?? '1'),
    });
    const walletPath = "m/44'/60'/0'/0/0";
    const deployer = ethers.Wallet.fromMnemonic(process.env.SECRET_NEUMONIC ?? "", walletPath);
    // const deployer = new ethers.Wallet(process.env.DEPLOYER_PRIVATE_KEY ?? '', provider);

    console.log('Deploying Diamond using account:', deployer.address);

    // Deploy DiamondCutFacet
    const diamondCutFacetFactory = new ethers.ContractFactory(DiamondCutFacet.abi, DiamondCutFacet.bytecode, deployer);
    const diamondCutFacet = await diamondCutFacetFactory.deploy();
    await diamondCutFacet.deployed();
    console.log('DiamondCutFacet deployed at:', diamondCutFacet.address);

    // Deploy DiamondLoupeFacet
    const diamondLoupeFacetFactory = new ethers.ContractFactory(DiamondLoupeFacet.abi, DiamondLoupeFacet.bytecode, deployer);
    const diamondLoupeFacet = await diamondLoupeFacetFactory.deploy();
    await diamondLoupeFacet.deployed();
    console.log('DiamondLoupeFacet deployed at:', diamondLoupeFacet.address);

    // Deploy OwnershipFacet
    const ownershipFacetFactory = new ethers.ContractFactory(OwnershipFacet.abi, OwnershipFacet.bytecode, deployer);
    const ownershipFacet = await ownershipFacetFactory.deploy();
    await ownershipFacet.deployed();
    console.log('OwnershipFacet deployed at:', ownershipFacet.address);

    // Deploy OwnershipFacet
    const diamondVaultFacetV1Factory = new ethers.ContractFactory(DiamondVaultFacetV1.abi, DiamondVaultFacetV1.bytecode, deployer);
    const diamondVaultFacetV1 = await diamondVaultFacetV1Factory.deploy();
    await diamondVaultFacetV1.deployed();
    console.log('DiamondVaultFacetV1 deployed at:', diamondVaultFacetV1.address);


    const diamondCut: [string, string[]][] = [
        // [diamondCutFacet.address, ethers.utils.id('diamondCut((address,uint256[],bytes)[])')],
        [diamondLoupeFacet.address, [ethers.utils.id('facetAddress(bytes4)'), ethers.utils.id('facetFunctionSelectors(address)'), ethers.utils.id('facetAddresses()')]],
        [ownershipFacet.address, [ethers.utils.id('owner()'), ethers.utils.id('transferOwnership(address)')]],
        [diamondVaultFacetV1.address, [ethers.utils.id('depositNative()'), ethers.utils.id('depositERC20(address,uint256)'), ethers.utils.id('balances(address)')]],
    ];

    // Deploy Diamond
    const diamondFactory = new ethers.ContractFactory(Diamond.abi, Diamond.bytecode, deployer);
    const diamond = await diamondFactory.deploy(diamondCutFacet.address);
    await diamond.deployed();
    console.log('Diamond deployed at:', diamond.address);

    await addDiamondCuts(diamond.address, diamondCut, deployer);




    // // Verify if the Diamond owner is the deployer
    // const diamondContract = new ethers.Contract(diamond.address, OwnershipFacet.abi, deployer);
    // const owner = await diamondContract.owner();
    // if (owner === deployer.address) {
    //     console.log('Diamond owner is set to deployer address:', owner);
    // } else {
    //     console.log('Error: Diamond owner is not the deployer address');
    // }

};

deployDiamond()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });