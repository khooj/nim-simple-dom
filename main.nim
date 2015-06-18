import httpclient, dom, os

if paramCount() < 1:
  quit("Need more args")

var html = getContent(paramStr(1))
var root: TreeNode = parseHtml(html)
printTree(root)
var elem = root.getElementByName("div")
if elem == root:
  echo("shit!")
else:
  echo("fuck ueah")

var anotherElem = root.getElementById("footer")
if anotherElem == root:
  echo("possible page doesnt have tag#footer :(")
else:
  echo("found tag#footer!")

var element2 = root.getElementByClass("footer")
if element2 == root:
  echo("neither page doesnt have tag:footer :(")
else:
  echo("found tag:footer!")
