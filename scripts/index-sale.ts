import { WETH, _0xUrl } from "./index-purchasing";
import { expandTo18Decimals, getAddresses, isCallingScript } from "./utils";

import { BigNumber } from "ethers";
import axios from "axios";
import { ethers } from "hardhat";
import { getContract } from "./contracts";
import qs from "querystring";

const addresses = getAddresses();

const getQuote = (
  sellToken: string,
  buyToken: string,
  sellAmount: BigNumber
) => {
  if (sellToken === buyToken || (buyToken === "WBNB" && sellToken === WETH))
    return Promise.resolve({
      data: {
        buyTokenAddress: sellToken,
        data: Buffer.from(""),
        to: ethers.constants.AddressZero,
      },
    });

  const params = {
    sellToken,
    buyToken,
    slippagePercentage: 0.01,
    sellAmount: sellAmount.toString(),
  };
  console.log(`${_0xUrl}/swap/v1/quote?${qs.stringify(params)}`);
  return axios.get(`${_0xUrl}/swap/v1/quote?${qs.stringify(params)}`);
};

const sellIndex = async (
  index: string,
  indexToken: string,
  sellAmount: BigNumber
) => {
  const [owner] = await ethers.getSigners();
  const indexContract = await getContract("Index", index);
  const composition = await indexContract.getComposition();
  const quoteRequests = composition.map((tokenCompo: any) =>
    getQuote(
      tokenCompo.token,
      "WBNB",
      tokenCompo.amount.mul(sellAmount).div(expandTo18Decimals(1))
    )
  );
  const quotes: any[] = await Promise.all(quoteRequests);

  const tx = await indexContract.sellIndex(
    quotes[0].data.buyTokenAddress,
    sellAmount,
    quotes[0].data.to,
    quotes.map((q: any) => ({
      callData: q.data.data,
      token: q.data.buyTokenAddress,
    }))
  );
  await tx.wait();
  const indexTokenContract = await getContract("IndexToken", indexToken);
  const balance = await indexTokenContract.balanceOf(owner.address);
  console.log("Balance", balance.toString());
};

if (isCallingScript(__filename))
  sellIndex(addresses.index, addresses.indexToken, expandTo18Decimals(1));

export default sellIndex;
