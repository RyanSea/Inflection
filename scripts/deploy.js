const main = async () => {
  
  console.log('Deploying!')
  const PointContract = await hre.ethers.getContractFactory('Point');
  const InflectionContract = await hre.ethers.getContractFactory('Inflection');

  const Point = await  PointContract.deploy();
  await Point.deployed();
  console.log('Point Address: ', Point.address);

  const Inflection = await InflectionContract.deploy(Point.address);
  await Inflection.deployed();
  console.log('Inflection Address: ', Inflection.address);

  const deployedPoint = await hre.ethers.getContractAt('Point', Point.address)
  await deployedPoint.transferOwnership(Inflection.address)
  
  console.log(`Point contract owner is: ${await deployedPoint.owner()}`)
    
};



  
const runMain = async () => {
    try {
      await main();
      process.exit(0);
    } catch (error) {
      console.error(error);
      process.exit(1);
    }
};
  
runMain();

