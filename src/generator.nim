import random, sequtils, strutils, tables, uri
from unicode import runes, toLower, toUTF8

randomize()

const
  mrkvStart = "__start"
  mrkvEnd = "__end"

proc unicodeStringToLower(str: string): string =
  result = ""
  for s in runes(str):
    result.add(s.toLower.toUTF8)

proc processSamples(samples: seq[string]): seq[string] =
  for sample in samples:
    let words = sample.split(" ")
    var subResult = @[mrkvStart]

    for word in words:
      if word.len == 0 or word == mrkvStart or word == mrkvEnd: continue

      if word.startsWith("http"):
        let sampleUri = parseUri(word)

        subResult.add(if sampleUri.scheme == "http" or sampleUri.scheme ==
            "https": word else: word.unicodeStringToLower())
      else:
        subResult.add(word.unicodeStringToLower())

    subResult.add mrkvEnd

    if subResult.len != 2: result.add(subResult.join(" "))

proc generate*(rawSamples: seq[string]; keySize: Positive; maxLength = 500;
    attempts = 500; begin = ""; count = 1): seq[string] =
  var
    samples = rawSamples.processSamples()
    words = samples.join(" ").split(" ")
    wordsLen = words.len

  samples.setLen(0)

  var dict: Table[string, seq[string]]

  for i in 0..(words.len - keySize):
    let
      prefix = words[i..<(i+keySize)].join(" ")
      suffix = if i + keySize < words.len: words[i + keySize] else: ""

    if prefix notin dict: dict[prefix] = @[]
    if suffix notin dict[prefix]: dict[prefix].add(suffix)

  words.setLen(0)

  proc generateLocal(): string =
    var
      prefix = if begin.len > 0: (mrkvStart & " " & begin) else: mrkvStart
      output = prefix.split(' ')
    prefix = output[^1]

    if not dict.hasKey(prefix):
      raise newException(CatchableError, "Prefix not found: " & prefix)

    for n in 1..wordsLen:
      let nextWord = dict[prefix].sample()
      if nextWord.len == 0 or nextWord == mrkvEnd: break
      output.add nextWord
      prefix = output[n..<(n + keySize)].join(" ")

    let procOutput = output.filter(proc(x: string): bool = x != mrkvStart and
        x != mrkvEnd)

    return procOutput.join(" ")

  proc generateAttempts(): string =
    for i in 0..<attempts:
      let res = generateLocal()
      if res.len > maxLength or res.len == 0: continue
      return res
    raise newException(CatchableError, "Out of attempts")

  try:
    for i in 0..<count:
      result.add generateAttempts()
  except CatchableError as e:
    dict.clear()
    result.setLen(0)
    raise e
  finally:
    dict.clear()
