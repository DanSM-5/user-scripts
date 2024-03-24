#!/usr/bin/env node

const permute = (arr, number = null) => {
  number = number === null ? arr.length - 1 : number;
  if (!number) console.log(arr.join(''));
  else {
    for (let i = 0; i <= number; i++) {
      permute(arr, number - 1);
      const swap = number % 2 === 0 ? i : 0;
      [ arr[swap], arr[number] ] = [ arr[number], arr[swap] ];
    }
  }
}

const swap = (arr, first, second) => [ arr[first], arr[second] ] = [ arr[second], arr[first] ];

// "Hello".split().forEach(stg => permute(1, stg.split('')));
