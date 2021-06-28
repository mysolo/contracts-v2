import { BigNumber } from 'ethers';
import axios from 'axios';
import { expandTo18Decimals } from './utils';
import qs from 'querystring';

const _0xUrl = "https://bsc.api.0x.org";

const getQuote = async (sellToken: string, buyToken: string, sellAmount: BigNumber) => {
	const params = {
		sellToken,
		buyToken,
		slippagePercentage: 1,
		sellAmount: sellAmount.toString(),
	}
	console.log(`${_0xUrl}/swap/v1/quote?${qs.stringify(params)}`);
	return await axios.get(`${_0xUrl}/swap/v1/quote?${qs.stringify(params)}`);
}

const purchaseIndex = async () => {
	const resp = await getQuote('BNB', '0x8ff795a6f4d97e7887c79bea79aba5cc76444adf', expandTo18Decimals(0.1));
	console.log(resp);
}

purchaseIndex();