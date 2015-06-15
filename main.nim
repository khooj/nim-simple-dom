import httpclient, os, parsexml, streams, strutils

if paramCount() < 1:
  quit("Need more args")

var html = getContent(paramStr(1))
var s = newStringStream(html)
var x: XmlParser
open(x, s, paramStr(1))
block mainLoop:
  while true:
    x.next()
    case x.kind:
    of xmlElementOpen:
    if x.elementName =?= "a":
      x.next()
      if x.kind == xmlAttribute:
        if x.attrKey =?= "href":
          var link = x.attrValue
          echo(link)
          while true:
            x.next()
            case x.kind:
            of xmlEof: break mainLoop
            of xmlElementClose: break
            else: discard
          x.next()
          var desc = ""
          while x.kind == xmlCharData:
            desc.add(x.charData)
            x.next()
          echo(desc & ":" & link)
    else:
      x.next()
  of xmlEof: break
  of xmlError:
    echo(errorMsg(x))
    x.next()
  else: x.next()

echo($links & " links found!")
x.close()
