import httpclient, dom, os

if paramCount() < 1:
  quit("Need more args")

var html = getContent(paramStr(1))
var root: TreeNode = parseHtml(html)
printTree(root)
var elem = root.getElementByName("div")
echo(repr(elem))
