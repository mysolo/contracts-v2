import { BigNumber, Contract } from "ethers";

import { expandTo18Decimals } from "./utils";

export const getTokenPriceUSD = async (
  token: string,
  router: Contract,
  BNB: string,
  BUSD: string
) => {
  let path = [token, BNB, BUSD];
  if (token === BNB) path = [token, BUSD];
  const amounts: BigNumber[] = await router.getAmountsOut(
    expandTo18Decimals(1),
    path
  );
  return token === BNB ? amounts[1] : amounts[2];
};

export const computeTargetWeights = async (
  tokens: string[],
  weights: number[],
  router: Contract,
  BNB: string,
  BUSD: string,
  multiplier: BigNumber
) => {
  let pricesUSDBN = [];
  for (const tok of tokens) {
    const p = await getTokenPriceUSD(tok, router, BNB, BUSD);
    pricesUSDBN.push(p);
  }
  const total = pricesUSDBN.reduce(
    (acc: BigNumber, p: any) => acc.add(p),
    BigNumber.from(0)
  );
  const adjustedWeights = pricesUSDBN.map((p: BigNumber, index: number) => {
    return BigNumber.from(weights[index]).mul(total).mul(multiplier).div(p);
  });
  return adjustedWeights;
};
