# Get the size of remote files with HEAD requests

Get the size of remote files with HEAD requests

## Usage

``` r
remote_sizes(file_url, timeout = 30)
```

## Arguments

- file_url:

  Character vector of urls.

- timeout:

  Numeric. Seconds to wait for each HEAD request.

## Value

A numeric vector with the remote `Content-Length` of each file. `NA`
when the request failed, the server sent no size, or the server answered
with an HTML page (ANAC's error / rate-limit page).
