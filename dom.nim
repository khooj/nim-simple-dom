import parsexml, streams, strutils

type
  Attribute = tuple[attr: string, value: string]
  TreeNode* = ref TreeNodeObj
  TreeNodeObj = object
    parent: TreeNode
    children: seq[TreeNode]
    data: tuple[name: string, attrs: seq[Attribute]]

proc add*(root: var TreeNode, node: TreeNode) =
  root.children.add(node)

var recursionlvl: int = 0

proc processCharData(x: var XmlParser): string =
  result = ""
  block mainLoop:
    while true:
      while x.kind == xmlCharData:
        result &= x.charData()
        x.next()
      if x.kind == xmlElementStart and x.elementName == "br":
        x.next()
      else:
        break mainLoop

proc isCouldClose(tag: string): bool =
  case tag:
  of "meta", "link", "hr", "input", "param", "source", "img", "br": return false
  else: return true

proc buildTree(root: var TreeNode, x: var XmlParser, parentTag: string = nil) =
  inc(recursionlvl)
  #echo("called buildTree (parent tag is" & parentTag & ')' & $recursionlvl)
  var node = root
  var name = ""
  var child: TreeNode
  while true:
    case x.kind:
    of xmlElementClose:
      x.next()
      if x.kind == xmlWhitespace:
        while x.kind == xmlWhitespace:
          x.next()
      if not isCouldClose(name):
        continue
      if x.kind == xmlElementOpen or x.kind == xmlElementStart:
        buildTree(child, x, name)
      elif x.kind == xmlCharData:
        child.data.attrs.add(("description", processCharData(x)))

    of xmlElementOpen:
      name = x.elementName
      child = TreeNode(parent: node, children: @[], data: (name: x.elementName, attrs: @[]))
      node.add(child)
      while x.kind != xmlElementClose:
        x.next()
        if x.kind == xmlAttribute:
          child.data.attrs.add((x.attrKey, x.attrValue))

    of xmlElementStart:
      name = x.elementName
      child = TreeNode(parent: node, children: @[], data: (name: x.elementName, attrs: @[]))
      node.add(child)
      x.next()
      if x.kind == xmlCharData:
        child.data.attrs.add(("description", processCharData(x)))
      if isCouldClose(name):
        buildTree(child, x, name)

    of xmlElementEnd:
      if parentTag != nil and x.elementName == parentTag:
        dec(recursionlvl)
        return
      x.next()

    of xmlWhitespace:
      x.next()

    of xmlError:
      echo(x.errorMsg())
      x.next()

    of xmlEof:
      dec(recursionlvl)
      return
    else: x.next()

proc sign(x: int): int =
  if x > 0: return 1
  else: return 0

proc printAttrs(node: TreeNode): string=
  result = ""
  for i in 0..high(node.data.attrs):
    result &= repeat(", ", sign(i)) & node.data.attrs[i].attr & ": " & node.data.attrs[i].value

proc printTree*(root: TreeNode, lvl: int = 0) =
  for i in 0..high(root.children):
    var node = root.children[i]
    echo(repeat('-', lvl) & node.data.name & '(' & printAttrs(node) & ')')
    printTree(node, lvl+1)

proc parseHtml*(html: string): TreeNode =
  result = TreeNode(children: @[])
  var s = newStringStream(html)
  var parser: XmlParser
  parser.open(s, "")
  parser.next()
  buildTree(result, parser)
  parser.close()
