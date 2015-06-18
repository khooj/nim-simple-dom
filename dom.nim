import parsexml, streams, strutils, queues

type
  Attribute = tuple[attr: string, value: string]
  TreeNode* = ref TreeNodeObj
  TreeNodeObj = object
    parent: TreeNode
    children: seq[TreeNode]
    data: tuple[name: string, attrs: seq[Attribute]]

proc add*(root: var TreeNode, node: TreeNode) =
  root.children.add(node)

proc searchAttr*(node: TreeNode, attr: string): string =
  for i in 0..high(node.data.attrs):
    if node.data.attrs[i].attr == attr:
      return node.data.attrs[i].value
  return ""

proc bfs(root: TreeNode, cmp: proc(node: TreeNode): bool): TreeNode =
  var queue = initQueue[TreeNode]()
  var currentNode = root
  while true:
    if cmp(currentNode):
      return currentNode
    for i in 0..high(currentNode.children):
      queue.add(currentNode.children[i])
    try:
      currentNode = queue.dequeue()
    except:
      return root

proc getElementByName*(root: TreeNode, name: string): TreeNode =
  return bfs(root, proc(n: TreeNode): bool =
    if n.data.name == name:
      return true
    else:
      return false
    )

proc getElementById*(root: TreeNode, id: string): TreeNode =
  return bfs(root, proc(n: TreeNode): bool =
    var attr = n.searchAttr("id")
    if attr != "" and attr == id:
      return true
    return false
  )

proc getElementByClass*(root: TreeNode, class: string): TreeNode =
  return bfs(root, proc(n: TreeNode): bool =
    var attr = n.searchAttr("class")
    if attr != "" and attr == class:
      return true
    return false
  )

proc getElementsByName*(root: TreeNode, name: string): seq[TreeNode] =
  var elems: seq[TreeNode] = @[]
  discard bfs(root, proc(n: TreeNode): bool =
    if n.data.name == name:
      elems.add(n)
    return false
  )
  return elems

proc getElementsByClass*(root: TreeNode, class: string): seq[TreeNode] =
  var elems: seq[TreeNode] = @[]
  discard bfs(root, proc(n: TreeNode): bool =
    var attr = n.searchAttr("class")
    if attr != "" and attr == class:
      elems.add(n)
    return false
  )
  return elems

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
  of "meta", "link", "hr", "input", "param", "source", "img", "br", "base": return false
  else: return true

proc buildTree(root: var TreeNode, x: var XmlParser, parentTag: string = nil) =
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
        return
      x.next()

    of xmlWhitespace:
      x.next()

    of xmlError:
      echo(x.errorMsg())
      x.next()

    of xmlEof:
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

