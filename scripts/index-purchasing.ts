import * as R from "ramda";

import { BigNumber } from "ethers";
import axios from "axios";
import deployAll from "./deploy-all";
import { ethers } from "hardhat";
import { expandTo18Decimals } from "./utils";
import { getContract } from "./contracts";
import qs from "querystring";

const _0xUrl = "https://bsc.api.0x.org";

const getQuote = (
  sellToken: string,
  buyToken: string,
  buyAmount: BigNumber
) => {
  const params = {
    sellToken,
    buyToken,
    slippagePercentage: 0.01,
    buyAmount: buyAmount.toString(),
  };
  console.log(`${_0xUrl}/swap/v1/quote?${qs.stringify(params)}`);
  return axios.get(`${_0xUrl}/swap/v1/quote?${qs.stringify(params)}`);
};

const purchaseIndex = async (
  index: string,
  indexToken: string,
  buyAmount: BigNumber
) => {
  const [owner] = await ethers.getSigners();
  const indexContract = await getContract("Index", index);
  const composition = await indexContract.getComposition();
  const quoteRequests = composition.map((tokenCompo: any) =>
    getQuote(
      //  "ETH",
      "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
      tokenCompo.token,
      tokenCompo.amount.mul(buyAmount).div(expandTo18Decimals(1))
    )
  );
  const quotes: any[] = await Promise.all(quoteRequests);

  let totalCost = quotes.reduce(
    (p, c) => BigNumber.from(c.data.sellAmount).add(p),
    BigNumber.from(0)
  );
  totalCost = totalCost.mul(101).div(100);
  console.log("total cost:", totalCost.toString());

  const tx = await indexContract.purchaseIndex(
    quotes[0].data.sellTokenAddress,
    totalCost,
    buyAmount,
    quotes[0].data.to,
    quotes.map((q: any) => ({
      callData: q.data.data,
      token: q.data.buyTokenAddress,
    })),
    {
      value: totalCost,
    }
  );
  await tx.wait();
  const indexTokenContract = await getContract("IndexToken", indexToken);
  const balance = await indexTokenContract.balanceOf(owner.address);
  console.log("Balance", balance.toString());
};

deployAll().then(({ index, indexToken }) =>
  purchaseIndex(index, indexToken, expandTo18Decimals(2))
);
