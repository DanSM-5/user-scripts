import sys

def getSafe(key, dic):
  return dic[key] if key in dic else None

def getKeyVal(string):
  idx = string.index("=")
  key = string[:idx]
  val = string[idx + 1:]
  return ( key, val )

def proccessArgs(arr):
  return { k: v for (k, v) in map(getKeyVal, arr) }

def getArgsAsDictionary():
  return proccessArgs(sys.argv[1:])
