stream = require "stream"

END     = 0o300 # indicates end of packet
ESC     = 0o333 # indicates byte stuffing
ESC_END = 0o334 # ESC ESC_END means END data byte
ESC_ESC = 0o336 # ESC ESC_ESC means ESC data byte

# A stream class which takes arbitrary binary data
# and outputs SLIP framed binary data.
class SlipEncoder extends stream.Stream
  constructor: (bufsize=65536)->
    @buffer = new Buffer(bufsize)
    @pos = 0
    @writable = true
    @readable = true

  write: (buffer, encoding)->
    try
      if Buffer.isBuffer(buffer)
        # size check
        @buffer[@pos++] = END
        i = 0
        len = buffer.length

        # for each byte in the buffer, set the appropriate character sequence
        while i < len
          # Buffer is to small to handle frame
          if @pos >= @buffer.length
            @pos = 0
            @emit("error", new Error("Buffer is to small"))
            return false

          byte = buffer[i++]
          switch byte
            # encode END
            when END
              @buffer[@pos++] = ESC
              @buffer[@pos++] = ESC_END
            # encode ESC
            when ESC
              @buffer[@pos++] = ESC
              @buffer[@pos++] = ESC_ESC
            # copy byte to @buffer
            else
              @buffer[@pos++] = byte
        # mark end
        @buffer[@pos++] = END
        # copy data to a new buffer
        buffer = new Buffer(@pos)
        @buffer.copy(buffer, 0, 0, @pos)
        @pos = 0
        # emit event data with newly created buffer
        @emit("data", buffer)
      else
        @write(new Buffer(buffer, encoding))
    catch e
      @emit("error", e)
    true

  # Implementation of Stream::end
  end: (buffer, encoding)->
    @write(buffer, encoding) if buffer
    @emit("end")

# A stream class which takes SLIP encoded data
# and outputs binary data.
class SlipDecoder extends stream.Stream
  constructor: (bufsize=65536)->
    @buffer = new Buffer(bufsize)
    @pos = 0
    @writable = true
    @readable = true

  protocolViolation: ->
    if @pos > 0
      buf = new Buffer(@pos)
      @buffer.copy(buf, 0, 0, @pos)
    @lastWasEsc = false
    @pos = 0
    @emit("error", new Error("Invalid data"), buf)

  write: (buffer, encoding)->
    try
      if Buffer.isBuffer(buffer)
        i = 0
        len = buffer.length
        while i < len
          byte = buffer[i++]

          # Buffer is to small to handle frame
          if @pos >= @buffer.length
            @emit("error", new Error("Buffer is to small"))
            @pos = 0
            return false

          if @lastWasEsc
            # if byte not one of these two
            # then we have a protocol violation.
            switch byte
              when ESC_END
                @buffer[@pos++] = END
              when ESC_ESC
                @buffer[@pos++] = ESC
              else
                @protocolViolation()
                return true
            @lastWasEsc = false
          else
            switch byte
              when END
                if @pos > 0
                  buf = new Buffer(@pos)
                  @buffer.copy(buf, 0, 0, @pos)
                  @emit("data", buf)
                  @pos = 0
              when ESC
                if (i + 1) <= len # bytes left?
                  # if the next byte not one of these two
                  # then we have a protocol violation.
                  byte = buffer[i++]
                  switch byte
                    when ESC_END
                      @buffer[@pos++] = END
                    when ESC_ESC
                      @buffer[@pos++] = ESC
                    else
                      @protocolViolation()
                      return true
                else
                  @lastWasEsc = true
              else
                @buffer[@pos++] = byte
      else
        @write(new Buffer(buffer, encoding))
    catch e
      @emit("error", e)
    true

  # Implementation of Stream::end
  end: (buffer, encoding)->
    @write(buffer, encoding) if buffer
    @emit("end")

module.exports.SlipDecoder = SlipDecoder
module.exports.SlipEncoder = SlipEncoder
module.exports.END = END
module.exports.ESC = ESC
module.exports.ESC_END = ESC_END
module.exports.ESC_ESC = ESC_ESC
