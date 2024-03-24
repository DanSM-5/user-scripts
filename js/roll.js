#!/usr/bin/env node

// Simple gacha roll simulator FGO

const roll = () => Math.floor(Math.random() * 10_000);

// 0 - 99 is 1% chace while 100 - 9999 represents the remaining 99%
const getValue = cardVal => {
  if (cardVal > 99) {
    return "Useless CE"; // Also 3* and 4* servant, who cares anyways
  } else if (cardVal > 69) {
    return "Spook"; // SSR but not the one in rate up (is a lie)
  } else {
    return "SSR"; // You got... but at what cost? e.e
  }
};

const getRandomCard = () => getValue(roll());

// const single = (title = 'Card') => ([{ [title]: getRandomCard() }]);

// Allow arbitrary length rolls, 10 is the default
const multy = (custom = 10) => new Array(custom)
  .fill(0)
  .reduce((acc, _, i) => {
    // acc.push(single(`Card ${i + 1}`)[0]);
    acc.push({ [`Card ${i + 1}`]: getRandomCard() });
    return acc;
  }, []);

const single = () => multy(1);

// Pretty print
const print = (cards) => console.table(
  cards.reduce((acc, card) => ({ ...acc, ...card }), {}),
);

// That's hell you're walking into 🔥
const rollSingle = () => print(single());
const rollMulty = () => print(multy());

