slip = require "../"
require "should"

describe "SlipEncoder", ->
  encoder = null

  beforeEach ->
    encoder = new slip.SlipEncoder(256)

  describe "constructor", ->
    it "should use a buffer with 65536 bytes default size", ->
      encoder = new slip.SlipEncoder
      encoder.buffer.should.have.length 65536

    it "should allow to manually specify the buffer size", ->
      encoder.buffer.should.have.length 256

  describe ".write", ->
    it "should emit 'data' with slip encoded data", (done)->
      encoder.on "data", (data)->
        data.length.should.be.equal 9
        data[0].should.be.equal slip.END
        data[1].should.be.equal slip.ESC
        data[2].should.be.equal slip.ESC_END
        data[3].should.be.equal slip.ESC
        data[4].should.be.equal slip.ESC_ESC
        data.toString("utf8", 5, 8).should.be.equal "foo"
        data[8].should.be.equal slip.END
        done()

      buffer = new Buffer(5)
      buffer[0] = slip.END
      buffer[1] = slip.ESC
      buffer.write("foo", 2)
      encoder.write buffer

    it "should emit an error if the buffer is full", (done)->
      encoder.on "error", (err)->
        err.should.be.instanceof Error
        err.message.should.be.equal "Buffer is to small"
        encoder.pos.should.be.equal 0
        done()

      buf = new Buffer(257)
      buf.fill(0)
      encoder.write(buf)

  describe ".end", ->

    it "should emit `end`", (done)->
      encoder.on("end", done)
      encoder.end()

    it "should write data before emitting `end` if called with data", (done)->
      data   = {}
      called = false

      encoder.write = (arg)->
        arg.should.be.equal data
        called = true

      encoder.on "end", ->
        called.should.be.true
        done()

      encoder.end(data)


describe "SlipDecoder", ->
  decoder = null

  beforeEach ->
    decoder = new slip.SlipDecoder(256)

  describe "constructor", ->
    it "should use a buffer with 65536 bytes default size", ->
      decoder = new slip.SlipDecoder
      decoder.buffer.should.have.length 65536

    it "should allow to manually specify the buffer size", ->
      decoder.buffer.should.have.length 256

  describe ".write", ->
    it "should emit 'data' with data decoded from SLIP encoded data", (done)->
      decoder.on "data", (data)->
        data[0].should.be.equal slip.END
        data[1].should.be.equal slip.ESC
        data[2].should.be.equal slip.END
        data[3].should.be.equal slip.ESC
        data.toString("utf8", 4, 19).should.be.equal "Addicted2Random"
        done()

      # write an ESC ESC_END sequenze
      buf = new Buffer(2)
      buf[0] = slip.ESC
      buf[1] = slip.ESC_END
      decoder.write(buf)

      # write an ESC ESC_ESC sequenze
      buf = new Buffer(2)
      buf[0] = slip.ESC
      buf[1] = slip.ESC_ESC
      decoder.write(buf)

      # write ESC ESC_END sequenze as two separate write calls
      buf = new Buffer(1)
      buf[0] = slip.ESC
      decoder.write(buf)
      buf = new Buffer(1)
      buf[0] = slip.ESC_END
      decoder.write(buf)

      # write ESC ESC_ESC sequenze as two separate write calls
      buf = new Buffer(1)
      buf[0] = slip.ESC
      decoder.write(buf)
      buf = new Buffer(1)
      buf[0] = slip.ESC_ESC
      decoder.write(buf)

      buf = new Buffer("Addic")
      decoder.write(buf)

      buf = new Buffer("ted2R")
      decoder.write(buf)

      buf = new Buffer(6)
      buf.write("andom")
      buf[5] = slip.END
      decoder.write(buf)

    it "should emit error with already recived data on protocol violations", ->
      called = 0

      decoder.on "error", (err, buf)->
        err.should.be.instanceof Error
        err.message.should.be.equal "Invalid data"
        buf.should.be.instanceof Buffer
        decoder.pos.should.be.equal 0
        called++

      # invalid sequenze of bytes
      buf = new Buffer(5)
      buf.write("foo")
      buf[3] = slip.ESC
      buf[4] = 12
      decoder.write(buf)

      # invalid sequenze of bytes in two separate write calls
      buf = new Buffer(4)
      buf.write("foo")
      buf[3] = slip.ESC
      decoder.write(buf)
      buf = new Buffer([12])
      decoder.write(buf)

      called.should.be.equal 2

    it "should emit an error if the buffer is full", (done)->
      decoder.on "error", (err)->
        err.should.be.instanceof Error
        err.message.should.be.equal "Buffer is to small"
        done()

      buf = new Buffer(257)
      buf.fill(0)
      buf[258] = 3
      decoder.write(buf)

  describe ".end", ->

    it "should emit `end`", (done)->
      decoder.on("end", done)
      decoder.end()

    it "should write data before emitting `end` if called with data", (done)->
      data   = {}
      called = false

      decoder.write = (arg)->
        arg.should.be.equal data
        called = true

      decoder.on "end", ->
        called.should.be.true
        done()

      decoder.end(data)

describe "SlipEncoder to SlipDecoder pipe", ->

  it "should pass data throug pipe", (done)->
    encoder = new slip.SlipEncoder(256)
    decoder = new slip.SlipDecoder(256)

    encoder.pipe(decoder)

    data = "Addicted2Random"

    decoder.on "data", (d)->
      d.toString().should.be.equal data
      done()

    buffer = new Buffer(data)
    encoder.write(buffer)
