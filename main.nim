import httpclient, os, parsexml, streams, strutils

proc `=?=` (a, b: string): bool =
  return cmpIgnoreCase(a, b) == 0

type
  TreeNode = ref TreeNodeObj
  TreeNodeObj = object
    parent: TreeNode
    children: seq[TreeNode]

proc add(root: var TreeNode, node: TreeNode): =
  root.children.add(node)

proc skipUntilXmlClose(x: var XmlParser): bool = 
  while true:
    x.next()
    case x.kind:
    of xmlError: return false
    of xmlEof: return false
    of xmlElementClose: return true
    else: discard

proc processATag(x: var XmlParser, l: var seq[string]): bool =
  while true:
    x.next()
    if x.kind == xmlAttribute:
      if x.attrKey =?= "title":
        if x.attrValue != nil: l.add(x.attrValue)
        return true
    elif x.kind == xmlElementClose:
      return true

proc rewindDivUntilClass(x: var XmlParser): bool =
  while true:
    x.next()
    if x.kind == xmlAttribute:
      if x.attrKey =?= "class":
        return true

proc searchTag(x: var XmlParser, tag: string): bool=
  while true:
    x.next()
    case x.kind:
    of xmlElementOpen:
      if x.elementName =?= tag:
        return true
    of xmlError: return false
    of xmlEof: return false

if paramCount() < 1:
  quit("Need more args")

var links: seq[string]
var html = getContent(paramStr(1))
var s = newStringStream(html)
var x: XmlParser
open(x, s, paramStr(1))
links = @[]
block mainLoop:
  while true:
    x.next()
    case x.kind:
    of xmlElementOpen:
      if x.elementName =?= "div":
        if rewindDivUntilClass(x):
          if x.attrValue =?= "post_image_block":
            if not searchAndProcessATag(x, links): break mainLoop
            x.next()
    of xmlEof: break
    of xmlError:
      echo(errorMsg(x))
    else: x.next()

echo(links)
x.close()
