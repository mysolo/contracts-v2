#!/bin/bash

SCRIPT=scripts/$1.ts
NETWORK=${2:-localhost}
CMD="npx hardhat run --network $NETWORK"
$CMD $SCRIPT