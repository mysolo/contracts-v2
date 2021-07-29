import { expandTo18Decimals, getAddresses, isCallingScript } from './utils';

import { BigNumber } from '@ethersproject/bignumber';
import { Contract } from 'ethers';
import deployMigrator from './deploy-migrator';
import { ethers } from 'hardhat';
import { formatEther } from '@ethersproject/units';
import { getContract } from './contracts';
import { getQuote } from './index-purchasing';

const main = async () => {
  const [us] = await ethers.getSigners();
  const migratorAddress = await deployMigrator();
  const migrator = await getContract("IndexMigration", migratorAddress);

  console.log("sending BNB to migrator...");
  const tx2 = us.sendTransaction({
    to: migratorAddress,
    value: expandTo18Decimals(10)
  });

  const indexV1Contract = await getContract("ERC20", getAddresses().tokens['LI-V1']);
  const balanceLiV1 = await indexV1Contract.balanceOf(us.address);
  console.log("Balance LI v1", formatEther(balanceLiV1));

  const indexV2Contract = await getContract("Index", getAddresses().indexes.LI);

  const amountOut = balanceLiV1.mul(95).div(100);

  console.log("approving index v1 to migrator contract");
  const tx0 = await indexV1Contract.approve(migratorAddress, balanceLiV1);
  await tx0.wait();

  const { swapTarget, orders } = await getQuotes(indexV2Contract, amountOut);
  const tx1 = await migrator.migration(getAddresses().tokens['LI-V1'], indexV2Contract.address,
    0,
    amountOut.mul(20).div(100), // min amount out is 90% of amount out
    swapTarget,
    orders
  );
  console.log("waiting for migration tx...");
  await tx1.wait();

  const balanceV1 = await indexV1Contract.balanceOf(us.address);
  console.log("balance v1", formatEther(balanceV1));

  const v2TokenAddress = await indexV2Contract._indexToken();
  const v2TokenContract = await getContract("IndexToken", v2TokenAddress);
  const balanceV2 = await v2TokenContract.balanceOf(us.address);
  console.log("balance v2", formatEther(balanceV2));
}

const getQuotes = async (indexV2Contract: Contract, buyAmount: BigNumber) => {
  const composition = await indexV2Contract.getComposition();
  const quoteRequests = composition.map((tokenCompo: any) =>
    getQuote(
      "WBNB",
      tokenCompo.token,
      tokenCompo.amount.mul(buyAmount).div(expandTo18Decimals(1))
    ).catch((err) => console.log(err))
  );
  const quotes: any[] = await Promise.all(quoteRequests);
  return {
    swapTarget: quotes[0].data.to,
    orders: quotes.map((q: any) => ({
      callData: q.data.data,
      token: q.data.buyTokenAddress
    }))
  };
}

if (isCallingScript(__filename))
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });