# Addicted2Random SLIP

A2R-SLIP contains two Node.js stream classes to encode and decode SLIP (RFC 1055) data.

This project was created as part of the [Addicted2Random](http://www.addicted2random.eu/) project.

## API

This package contains two classes, SlipEncoder and SlipDecoder.
Both classes implement the Node.js writable and readable stream-interface.

Their constructors take an optional argument to define the internal buffer size
(in bytes) of the streams, the default size is 65536.

The SlipEncoder takes arbitrary binary data and outputs SLIP framed binary data.
The SlipDecoder takes SLIP encoded data and outputs decoded binary data.

### Example

``` coffee
encoder = new SlipEncoder(512)
decoder = new SlipDecoder(512)

encoder.pipe(decoder)

decoder.on "data", (data)->
  doSomethingUseful(data)

encoder.write(aDataBuffer)
```

For a more useful example have a look under [a2r-osc](http://github.com/beyama/a2r-osc)
in the 'osc.UnpackStream and osc.PackStream' section. There we're using these streaming
classes to send and receive Open Sound Control data over a TCP connection.

## How to contribute

If you find what looks like a bug:

Check the GitHub issue tracker to see if anyone else has reported an issue.

If you don't see anything, create an issue with information about how to reproduce it.

If you want to contribute an enhancement or a fix:

Fork the project on Github.

Make your changes with tests.

Commit the changes without making changes to any files that aren't related to your enhancement or fix.

Send a pull request.

## License

Created by [Alexander Jentz](http://beyama.de), Germany.

MIT License. See the included MIT-LICENSE file.
