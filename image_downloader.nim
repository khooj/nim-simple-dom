import httpclient, os, dom, uri

if paramCount() < 1:
  quit("Need more args")

let user_agent = "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
let html_content = getContent(paramStr(1))
var root = parseHtml(html_content)
var imgs = root.getElementsByClass("img_filename")
var img_urls: seq[string] = @[]
for i in imgs:
  let url = i.searchAttr("title")
  if url != "":
    img_urls.add(url)

if not existsDir("downloaded_imgs"):
  createDir("downloaded_imgs")

var idx = 0
const default_timeout = 500
const timeout_step = 500
const timeout_threhold = 2500
const max_attempts = 3
var timeout = default_timeout
var attempts = 0
let fast_skip = true
for i in img_urls:
  inc(idx)
  let count = $idx & '/' & $len(img_urls)
  let uri_obj = parseUri(i)
  let (dir, filename, ext) = splitFile(uri_obj.path)
  block mainLoop:
    while true:
      try:
        downloadFile(i, "downloaded_imgs" & '/' & filename & ext, userAgent = user_agent)
        echo("Downloaded " & count & " image from " & uri_obj.hostname)
        timeout = default_timeout
        break
      except:
        if fast_skip:
          echo("Timeout for image " & count &", skipping wihout retries")
          break mainLoop
        if attempts >= max_attempts:
          echo("Skipping image, host possible dead")
          attempts = 0
          timeout = default_timeout
          break mainLoop
        else:
          echo("Timeout for image, trying again from " & uri_obj.hostname)
          timeout += timeout_step
          if timeout > timeout_threhold:
            timeout = timeout_threhold
            inc(attempts)
            echo($attempts & '/' & $max_attempts & " attempts at max timeout")
      finally:
        sleep(timeout)


  
