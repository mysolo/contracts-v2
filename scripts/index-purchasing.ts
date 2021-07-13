import * as R from "ramda";

import { expandTo18Decimals, getAddresses, isCallingScript } from "./utils";

import { BigNumber } from "ethers";
import axios from "axios";
import { ethers } from "hardhat";
import { getContract } from "./contracts";
import qs from "querystring";

const addresses = getAddresses();
export const _0xUrl = "https://bsc.api.0x.org";
const WETH = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";

const getQuote = (
  sellToken: string,
  buyToken: string,
  buyAmount: BigNumber
) => {
  if (sellToken === buyToken || (buyToken === WETH && sellToken === "WBNB"))
    return Promise.resolve({
      data: {
        sellAmount: buyAmount,
        buyTokenAddress: buyToken,
        data: Buffer.from(""),
      },
    });
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
  const buyToken = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee";
  const quoteRequests = composition.map((tokenCompo: any) =>
    getQuote(
      "WBNB",
      tokenCompo.token,
      tokenCompo.amount.mul(buyAmount).div(expandTo18Decimals(1))
    ).catch((err) => console.log(err))
  );
  const quotes: any[] = await Promise.all(quoteRequests);

  let totalCost = quotes.reduce(
    (p, c) => BigNumber.from(c.data.sellAmount).add(p),
    BigNumber.from(0)
  );
  console.log("Price", totalCost.toString());
  // 1% for slippage
  totalCost = totalCost.mul(101).div(100);
  console.log("balance before", (await owner.getBalance()).toString());

  const fee = totalCost.div(100);

  const tx = await indexContract.purchaseIndex(
    buyToken,
    totalCost,
    buyAmount,
    quotes[0].data.to,
    quotes.map((q: any) => ({
      callData: q.data.data,
      token: q.data.buyTokenAddress,
    })),
    {
      value: totalCost.add(fee),
    }
  );
  await tx.wait();
  const indexTokenContract = await getContract("IndexToken", indexToken);
  const balance = await indexTokenContract.balanceOf(owner.address);
  console.log("Balance", balance.toString());
  console.log("balance eth after", (await owner.getBalance()).toString());
};

if (isCallingScript(__filename))
  purchaseIndex(addresses.index, addresses.indexToken, expandTo18Decimals(4))
    .then(() => process.exit(0))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
