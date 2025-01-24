import functools

def bind(func, value):
  result = func(value) if value is not None else value
  return lambda next: bind(next, result) if next is not None else result

def getReducer(reducer):
  count = 0
  def temp(acc, curr):
    nonlocal count
    ret = reducer(acc, curr, count)
    count += 1
    return ret
  return temp

def reduceCallback(acc, curr, idx):
  if idx % 2 == 0:
    acc.append(curr)
  else:
    acc[len(acc) - 1] += curr
  return acc

def convertFromHexString(value):
  arr = list(value)
  reduced = functools.reduce(getReducer(reduceCallback), arr, [])
  mapped = map(lambda ch: bytes.fromhex(ch).decode("utf-8"), reduced)
  return functools.reduce(lambda str, ch: str + ch, mapped, "")

def getValue(value):
  if (len(value) == 16):
    return value
  elif (len(value) == 32):
    return convertFromHexString(value)
  else:
    return None

def getEncoded(value):
  return bytes(value, "utf-8")

def getBites(string):
  return bind(getValue, string)(getEncoded)(None)