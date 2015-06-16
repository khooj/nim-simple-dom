import httpclient, os, parsexml, streams, strutils

proc `=?=` (a, b: string): bool =
  return cmpIgnoreCase(a, b) == 0

type
  TreeNode = ref TreeNodeObj
  TreeNodeObj = object
    parent: TreeNode
    children: seq[TreeNode]
    data: tuple[name: string, attrs: seq[tuple[attr: string, value: string]]]

proc add(root: var TreeNode, node: TreeNode) =
  root.children.add(node)

proc buildTree(root: var TreeNode, x: var XmlParser, parentTag: string) =
  var node = root
  var name = ""
  var child: TreeNode
  while true:
    case x.kind:
    of xmlElementClose:
      x.next()
      buildTree(child, x, name)
    of xmlElementOpen:
      name = x.elementName
      child = TreeNode(parent: node, children: @[], data: (name: x.elementName, attrs: @[]))
      node.add(child)
      while x.kind != xmlElementClose:
        x.next()
        if x.kind == xmlAttribute:
          child.data.attrs.add((x.attrKey, x.attrValue))
      x.next()
    of xmlElementStart:
      name = x.elementName
      child = TreeNode(parent: node, children: @[], data: (name: x.elementName, attrs: @[]))
      node.add(child)
      x.next()
      buildTree(child, x, name)
    of xmlElementEnd: 
      if x.elementName == parentTag:
        return
      x.next()
    of xmlError:
      echo(x.errorMsg())
      x.next()
    of xmlEof: return
    else: x.next()

proc traverseTree(root: TreeNode, lvl: int) =
  for i in 0..high(root.children):
    var node = root.children[i]
    echo(repeat(' ', lvl) & node.data.name)
    traverseTree(node, lvl+1)

if paramCount() < 1:
  quit("Need more args")

#var html = getContent(paramStr(1))
var html = """
<html>
<head>
<script href="some javascript">some data</script>
<link href="asd"/>
</head>
<body>
<div><a href="asd"></a><a href="seconda"></a></div><div><img src="asdasdasd"></div>
</body>
</html>
"""
var s = newStringStream(html)
var x: XmlParser
var root: TreeNode = TreeNode(children: @[])
open(x, s, paramStr(1))
x.next()
buildTree(root, x, "")
traverseTree(root, 0)
x.close()
